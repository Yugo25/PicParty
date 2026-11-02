-- One-to-one messages. Run after 117_avatars.sql.
--
-- Sending, starting a conversation and marking it read already exist in
-- 000_core.sql (send_message, get_or_create_conversation,
-- mark_conversation_read). This adds the two ways to read them back.

-- Every list below reads a conversation's newest messages first.
create index if not exists messages_conversation_idx on public.messages(conversation_id, created_at desc);

-- 1. A conversation's messages, newest first, one page at a time (pass the
-- oldest loaded message's created_at as p_before for the next page). Only the
-- two people in the conversation get any rows.
create or replace function public.get_messages(
  p_conversation_id uuid,
  p_before timestamptz default null,
  p_limit integer default 50
) returns setof public.messages language sql stable security definer set search_path=public as $$
  select m.*
  from messages m
  where m.conversation_id=p_conversation_id
    and m.deleted_at is null
    and exists(select 1 from conversation_members cm where cm.conversation_id=p_conversation_id and cm.user_id=auth.uid())
    and (p_before is null or m.created_at<p_before)
  order by m.created_at desc
  limit least(greatest(p_limit, 1), 100);
$$;
grant execute on function public.get_messages(uuid, timestamptz, integer) to authenticated;

-- 2. The Messages list: the signed-in person's conversations, most recent
-- first, each with the other person, the last message and how many messages
-- they haven't read. Conversations with no messages yet and people either
-- side has blocked are left out.
create or replace function public.get_conversations() returns setof jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object(
    'id', c.id,
    'other', profile_json(o.other_id),
    'last_text', l.content,
    'last_sender_id', l.sender_id,
    'updated_at', l.created_at,
    'unread', (
      select count(*) from messages u
      where u.conversation_id=c.id
        and u.sender_id<>auth.uid()
        and u.deleted_at is null
        and (me.last_read_at is null or u.created_at>me.last_read_at)
    )
  )
  from conversation_members me
  join conversations c on c.id=me.conversation_id
  cross join lateral (select case when c.user_a_id=auth.uid() then c.user_b_id else c.user_a_id end as other_id) o
  join lateral (
    select m.content, m.sender_id, m.created_at from messages m
    where m.conversation_id=c.id and m.deleted_at is null
    order by m.created_at desc
    limit 1
  ) l on true
  where me.user_id=auth.uid()
    and not users_are_blocked(auth.uid(), o.other_id)
  order by l.created_at desc;
$$;
grant execute on function public.get_conversations() to authenticated;
