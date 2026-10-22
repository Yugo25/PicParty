-- Shared Parties, photos, likes, comments and follows. Run after 115_signup.sql.
--
-- The app reads everything through the functions below. Each one checks what
-- the signed-in person may see (can_view_party), so private Parties never leak.

-- 1. There is no image-processing server, so a photo is ready as soon as its
-- upload finishes (until now posts stayed 'processing' and could not be
-- liked or commented on).
create or replace function public.media_upload_completed(mid uuid) returns boolean language plpgsql security definer set search_path=public as $$
declare
  pid uuid;
begin
  update media_posts set processing_status='ready'
    where id=mid and user_id=auth.uid() and processing_status in ('uploading','processing')
    returning party_id into pid;
  if pid is null then
    return false;
  end if;
  update parties set last_activity_at=now() where id=pid;
  return true;
end $$;
grant execute on function public.media_upload_completed(uuid) to authenticated;

-- A Party scheduled for later is created as 'scheduled' and nothing switches
-- it to 'live', so decide by the clock instead of the stored status.
create or replace function public.party_is_live(pid uuid) returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from parties where id=pid and status in ('scheduled','live') and now()>=start_at and now()<end_at);
$$;

-- 2. JSON building blocks shared by the functions below.
create or replace function public.profile_json(uid uuid) returns jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object('id', p.id, 'username', p.username, 'display_name', p.display_name, 'avatar_url', p.avatar_url)
  from profiles p where p.id=uid;
$$;

create or replace function public.post_json(m public.media_posts) returns jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object(
    'id', m.id,
    'party_id', m.party_id,
    'path', m.original_storage_path,
    'caption', m.caption,
    'created_at', m.created_at,
    'like_count', m.like_count,
    'comment_count', m.comment_count,
    'liked', exists(select 1 from likes l where l.media_id=m.id and l.user_id=auth.uid()),
    'author', profile_json(m.user_id)
  );
$$;

-- Popularity for "Trending": likes plus three points per person who posted.
create or replace function public.party_trend(pid uuid) returns bigint language sql stable security definer set search_path=public as $$
  select coalesce(sum(like_count), 0) + 3 * count(distinct user_id)
  from media_posts where party_id=pid and processing_status='ready';
$$;

-- A Party with its host, counts, the viewer's membership and its newest posts.
create or replace function public.party_json(p public.parties, post_limit integer) returns jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object(
    'id', p.id,
    'title', p.title,
    'description', p.description,
    'category', p.category,
    'cover_path', p.cover_storage_path,
    'countdown_style', p.countdown_style,
    'privacy', p.privacy,
    'start_at', p.start_at,
    'end_at', p.end_at,
    'created_at', p.created_at,
    'owner_id', p.owner_id,
    'owner', profile_json(p.owner_id),
    'member_count', (select count(*) from party_members m where m.party_id=p.id and m.status='active'),
    'contributor_count', (select count(distinct user_id) from media_posts m where m.party_id=p.id and m.processing_status='ready'),
    'is_member', exists(select 1 from party_members m where m.party_id=p.id and m.user_id=auth.uid() and m.status='active'),
    'from_following', exists(select 1 from follows f where f.follower_id=auth.uid() and f.following_id=p.owner_id),
    'trend', party_trend(p.id),
    'posts', coalesce((
      select jsonb_agg(post_json(s.m) order by (s.m).created_at desc)
      from (select m from media_posts m where m.party_id=p.id and m.processing_status='ready' order by m.created_at desc limit post_limit) s(m)
    ), '[]'::jsonb)
  );
$$;

-- 3. Party lists.
--   for_you / following   Home ("following" = hosted by people you follow)
--   live / trending / newest / ending_soon / everything   Explore (public only)
--   hosted / joined       A profile's Parties (p_user)
create or replace function public.get_parties(
  p_view text,
  p_user uuid default null,
  p_text text default '',
  p_category text default null,
  p_limit integer default 20,
  p_offset integer default 0
) returns setof jsonb language sql stable security definer set search_path=public as $$
  with q as (select '%' || lower(trim(coalesce(p_text, ''))) || '%' as pattern)
  select party_json(p, 20)
  from parties p, q
  where auth.uid() is not null
    and p.status <> 'deleting'
    and can_view_party(p.id)
    and case p_view
      when 'for_you' then p.privacy='public' or p.owner_id=auth.uid() or is_party_member(p.id)
      when 'following' then (p.privacy='public' or is_party_member(p.id))
        and exists(select 1 from follows f where f.follower_id=auth.uid() and f.following_id=p.owner_id)
      when 'hosted' then p.owner_id=p_user
        and (p.privacy='public' or p_user=auth.uid() or is_party_member(p.id))
      when 'joined' then p.owner_id<>p_user
        and exists(select 1 from party_members m where m.party_id=p.id and m.user_id=p_user and m.status='active')
        and (p.privacy='public' or p_user=auth.uid() or is_party_member(p.id))
      else p.privacy='public'
        and (p_category is null or p.category=p_category)
        and (q.pattern='%%'
          or lower(p.title) like q.pattern
          or lower(coalesce(p.description, '')) like q.pattern
          or lower(coalesce(p.category, '')) like q.pattern
          or exists(select 1 from profiles o where o.id=p.owner_id and (o.username like q.pattern or lower(coalesce(o.display_name, '')) like q.pattern)))
        and case p_view
          when 'live' then now()>=p.start_at and now()<p.end_at
          when 'ending_soon' then now()>=p.start_at and now()<p.end_at
          when 'trending' then now()<p.end_at
          when 'newest' then now()<p.end_at
          else true
        end
    end
  order by
    case when p_view='ending_soon' then p.end_at end asc,
    case when p_view in ('live', 'trending') then party_trend(p.id) end desc,
    case when p_view='newest' then p.created_at end desc,
    -- "everything": open Parties first (by popularity), then ended ones, newest first.
    case when p_view='everything' then now()>=p.end_at end asc,
    case when p_view='everything' and now()<p.end_at then party_trend(p.id) end desc,
    case when p_view='everything' then p.end_at end desc,
    p.last_activity_at desc,
    p.created_at desc
  limit least(greatest(p_limit, 1), 50) offset greatest(p_offset, 0);
$$;
grant execute on function public.get_parties(text, uuid, text, text, integer, integer) to authenticated;

-- One Party with all its posts. A private Party you can't open comes back as
-- {id, locked: true}, so the app can say "private" instead of "not found".
create or replace function public.get_party(pid uuid) returns jsonb language sql stable security definer set search_path=public as $$
  select case when can_view_party(p.id) then party_json(p, 500) else jsonb_build_object('id', p.id, 'locked', true) end
  from parties p
  where p.id=pid and p.status <> 'deleting' and auth.uid() is not null;
$$;
grant execute on function public.get_party(uuid) to authenticated;

-- A person's posts (profile "Posts" tab), each with its Party.
create or replace function public.get_user_posts(p_user uuid, p_limit integer default 60) returns setof jsonb language sql stable security definer set search_path=public as $$
  select post_json(m) || jsonb_build_object('party', party_json(p, 1))
  from media_posts m
  join parties p on p.id=m.party_id
  where m.user_id=p_user
    and m.processing_status='ready'
    and p.status <> 'deleting'
    and can_view_party(p.id)
    and (p.privacy='public' or p_user=auth.uid() or is_party_member(p.id))
  order by m.created_at desc
  limit least(greatest(p_limit, 1), 100);
$$;
grant execute on function public.get_user_posts(uuid, integer) to authenticated;

-- 4. Comments of one post, oldest first, with who wrote them.
create or replace function public.get_comments(p_media_id uuid) returns setof jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object(
    'id', c.id, 'media_id', c.media_id, 'user_id', c.user_id, 'content', c.content,
    'parent_id', c.parent_id, 'created_at', c.created_at, 'updated_at', c.updated_at,
    'username', pr.username, 'display_name', pr.display_name, 'avatar_url', pr.avatar_url
  )
  from comments c
  join media_posts m on m.id=c.media_id
  join profiles pr on pr.id=c.user_id
  where c.media_id=p_media_id and can_view_party(m.party_id)
  order by c.created_at asc
  limit 500;
$$;
grant execute on function public.get_comments(uuid) to authenticated;

-- 5. People.
create or replace function public.get_profile_card(p_user uuid) returns jsonb language sql stable security definer set search_path=public as $$
  select profile_json(p.id) || jsonb_build_object(
    'bio', p.bio,
    'followers', (select count(*) from follows where following_id=p.id),
    'following', (select count(*) from follows where follower_id=p.id)
  )
  from profiles p
  where p.id=p_user and auth.uid() is not null and not users_are_blocked(auth.uid(), p.id);
$$;
grant execute on function public.get_profile_card(uuid) to authenticated;

create or replace function public.search_people(p_text text, p_limit integer default 40, p_offset integer default 0) returns setof jsonb language sql stable security definer set search_path=public as $$
  select profile_json(p.id)
  from profiles p
  where auth.uid() is not null
    and p.id <> auth.uid()
    and not users_are_blocked(auth.uid(), p.id)
    and (trim(coalesce(p_text, ''))=''
      or p.username like '%' || lower(trim(p_text)) || '%'
      or lower(coalesce(p.display_name, '')) like '%' || lower(trim(p_text)) || '%')
  order by p.created_at desc
  limit least(greatest(p_limit, 1), 100) offset greatest(p_offset, 0);
$$;
grant execute on function public.search_people(text, integer, integer) to authenticated;

-- The ids you follow, so Follow buttons know their state right away.
create or replace function public.get_my_following() returns setof uuid language sql stable security definer set search_path=public as $$
  select following_id from follows where follower_id=auth.uid();
$$;
grant execute on function public.get_my_following() to authenticated;
