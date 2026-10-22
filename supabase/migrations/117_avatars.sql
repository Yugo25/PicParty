-- Profile photos. Run after 116_sharing.sql.

-- 1. Avatars appear next to every post, comment and search result, so the
-- profile-media bucket is made public: photos load straight from their URL
-- without signing each one. Only avatars are stored here (paths {userId}/...),
-- and profiles are already visible to everyone signed in.
update storage.buckets set public=true where id='profile-media';

-- Replacing a photo removes the old file.
drop policy if exists profile_media_delete on storage.objects;
create policy profile_media_delete on storage.objects for delete to authenticated
  using(bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text);

-- 2. Sets (or with null, removes) the signed-in person's photo. Only a URL
-- inside their own profile-media folder is accepted.
create or replace function public.set_my_avatar(p_url text) returns public.profiles language plpgsql security definer set search_path=public as $$
declare
  r public.profiles;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if p_url is not null and position('/storage/v1/object/public/profile-media/' || auth.uid()::text || '/' in p_url) = 0 then
    raise exception 'INVALID_AVATAR';
  end if;
  update profiles set avatar_url=p_url, updated_at=now() where id=auth.uid() returning * into r;
  return r;
end $$;
grant execute on function public.set_my_avatar(text) to authenticated;
