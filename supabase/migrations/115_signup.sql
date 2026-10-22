-- Sign up from the app. Run after 114_new_ui.sql.

-- 1. The sign-up screen checks a username before creating the account.
-- Signed-out visitors can't read profiles, so ask through a helper that
-- only answers yes or no.
create or replace function public.username_available(p_username text) returns boolean language sql stable security definer set search_path=public as $$
  select not exists(select 1 from profiles where username=lower(trim(p_username)));
$$;
grant execute on function public.username_available(text) to anon, authenticated;

-- 2. Creating the profile must never fail the sign-up. Usernames that are too
-- long are cut to 30 characters, and a taken one (two people signing up at
-- the same moment) gets a short suffix from the user id.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare
  base text;
begin
  base := left(lower(regexp_replace(coalesce(new.raw_user_meta_data->>'user_name', 'user'), '[^a-zA-Z0-9_.]', '', 'g')), 30);
  if char_length(base) < 3 then
    base := 'user_' || substr(new.id::text, 1, 8);
  end if;
  if exists(select 1 from profiles where username = base) then
    base := left(base, 25) || '_' || substr(new.id::text, 1, 4);
  end if;
  insert into public.profiles(id, username, display_name)
    values(new.id, base, nullif(trim(new.raw_user_meta_data->>'display_name'), ''))
    on conflict(id) do nothing;
  return new;
end $$;
