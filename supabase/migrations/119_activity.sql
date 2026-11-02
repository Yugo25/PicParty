-- Inbox › Activity and the Inbox dot. Run after 118_chat.sql.
--
-- Likes, comments, replies and follows are already recorded in notifications
-- by like_media, create_comment and follow_user (000_core.sql). This reads
-- them back. Invites are left for later: nothing in the app sends them yet.

-- Liking twice (like, unlike, like) records two notifications; this finds the
-- newest one per person and post quickly.
create index if not exists notifications_recipient_type_idx on public.notifications(recipient_id, type, created_at desc);

-- 1. Activity, newest first. One row per person, kind and post (liking the
-- same photo twice shows once). Likes taken back and follows undone are left
-- out, as are people either side has blocked and posts the viewer can no
-- longer see.
create or replace function public.get_activity(p_limit integer default 50) returns setof jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object(
    'id', n.id,
    'type', n.type,
    'actor', profile_json(n.actor_id),
    'party_id', m.party_id,
    'media_id', n.media_id,
    'comment', c.content,
    'created_at', n.created_at
  )
  from (
    select distinct on (x.actor_id, x.type, x.media_id, x.comment_id) x.*
    from notifications x
    where x.recipient_id=auth.uid()
      and x.type in ('like', 'comment', 'reply', 'follow')
    order by x.actor_id, x.type, x.media_id, x.comment_id, x.created_at desc
  ) n
  left join media_posts m on m.id=n.media_id
  left join comments c on c.id=n.comment_id
  where n.actor_id is not null
    and not users_are_blocked(auth.uid(), n.actor_id)
    and (n.media_id is null or (m.processing_status='ready' and can_view_party(m.party_id)))
    and case n.type
      when 'like' then exists(select 1 from likes l where l.media_id=n.media_id and l.user_id=n.actor_id)
      when 'follow' then exists(select 1 from follows f where f.follower_id=n.actor_id and f.following_id=auth.uid())
      else true
    end
  order by n.created_at desc
  limit least(greatest(p_limit, 1), 100);
$$;
grant execute on function public.get_activity(integer) to authenticated;

-- 2. Whether the Inbox dot should show: unread messages, or Activity not
-- seen yet (mark_all_notifications_read clears the second when Activity is
-- opened).
create or replace function public.get_inbox_unread() returns jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object(
    'messages', exists(
      select 1
      from conversation_members me
      join conversations c on c.id=me.conversation_id
      join messages u on u.conversation_id=c.id
      where me.user_id=auth.uid()
        and u.sender_id<>auth.uid()
        and u.deleted_at is null
        and (me.last_read_at is null or u.created_at>me.last_read_at)
        and not users_are_blocked(auth.uid(), u.sender_id)
    ),
    'activity', exists(
      select 1 from notifications n
      where n.recipient_id=auth.uid()
        and not n.is_read
        and n.type in ('like', 'comment', 'reply', 'follow')
        and n.actor_id is not null
        and not users_are_blocked(auth.uid(), n.actor_id)
    )
  );
$$;
grant execute on function public.get_inbox_unread() to authenticated;
