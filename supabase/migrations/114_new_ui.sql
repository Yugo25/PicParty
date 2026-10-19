-- Fixes and additions for the new UI. Run after 000_core.sql.

-- 1. Timer styles: the new UI offers digital / minimal / ring.
alter table public.parties drop constraint if exists parties_countdown;
alter table public.parties add constraint parties_countdown check(countdown_style in ('digital','minimal','ring','motor','rock','gothic','sweet','cartoon','dream','cinema','flip','festival','cyber'));

-- 2. The parties and party_members read policies looked each other up, which
-- Postgres rejects ("infinite recursion detected in policy"). Check through
-- security definer helpers instead, which read the tables without RLS.
create or replace function public.is_party_owner(pid uuid) returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from parties where id=pid and owner_id=auth.uid());
$$;
create or replace function public.is_party_member(pid uuid) returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from party_members where party_id=pid and user_id=auth.uid() and status='active');
$$;

drop policy if exists parties_public_select on public.parties;
create policy parties_public_select on public.parties for select to authenticated
  using(privacy='public' or owner_id=auth.uid() or public.is_party_member(id));

drop policy if exists members_select on public.party_members;
create policy members_select on public.party_members for select to authenticated
  using(user_id=auth.uid() or public.is_party_owner(party_id));

-- 3. Storage access. 000_core.sql creates the buckets but no policies, so
-- every upload and download was refused.
--
-- party-media paths:
--   {partyId}/{userId}/{mediaId}/...  a post (only while the Party is live, by a member)
--   covers/{userId}/...               a Party cover, uploaded before the Party exists
create or replace function public.can_upload_party_media(object_name text) returns boolean language plpgsql stable security definer set search_path=public as $$
declare
  parts text[] := storage.foldername(object_name);
  pid uuid;
begin
  if auth.uid() is null or coalesce(array_length(parts, 1), 0) < 2 or parts[2] <> auth.uid()::text then
    return false;
  end if;
  if parts[1] = 'covers' then
    return true;
  end if;
  begin
    pid := parts[1]::uuid;
  exception when invalid_text_representation then
    return false;
  end;
  return party_is_live(pid) and is_party_member(pid);
end $$;

create or replace function public.can_view_party_media(object_name text) returns boolean language plpgsql stable security definer set search_path=public as $$
declare
  parts text[] := storage.foldername(object_name);
  pid uuid;
begin
  if auth.uid() is null or coalesce(array_length(parts, 1), 0) < 1 then
    return false;
  end if;
  if parts[1] = 'covers' then
    return true;
  end if;
  begin
    pid := parts[1]::uuid;
  exception when invalid_text_representation then
    return false;
  end;
  return can_view_party(pid);
end $$;

drop policy if exists party_media_insert on storage.objects;
create policy party_media_insert on storage.objects for insert to authenticated
  with check(bucket_id='party-media' and public.can_upload_party_media(name));

drop policy if exists party_media_select on storage.objects;
create policy party_media_select on storage.objects for select to authenticated
  using(bucket_id='party-media' and public.can_view_party_media(name));

-- profile-media paths: {userId}/... (avatars). Anyone signed in can view.
drop policy if exists profile_media_insert on storage.objects;
create policy profile_media_insert on storage.objects for insert to authenticated
  with check(bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists profile_media_update on storage.objects;
create policy profile_media_update on storage.objects for update to authenticated
  using(bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists profile_media_select on storage.objects;
create policy profile_media_select on storage.objects for select to authenticated
  using(bucket_id='profile-media');
