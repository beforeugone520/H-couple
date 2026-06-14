# Supabase Storage Policies

Create a private bucket named `moments`.

Object path format:

```text
{coupleSpaceId}/{userId}/{uuid}.{extension}
```

Required policies:

- Authenticated users can upload to `moments` when the first path segment is a `couple_space_id` they belong to.
- Authenticated users can read objects when they belong to the `couple_space_id` in the first path segment.
- Authenticated users can delete only objects under their own `{userId}` path segment.

Keep the bucket private. Store object paths in `moments.media_urls`; clients request signed URLs for display.

## Executable policies (SQL)

Run this in the Supabase SQL editor after creating the private `moments` bucket. It relies on
`public.is_space_member(space_id uuid)` from `docs/api/supabase-schema.sql`. Path layout is
`{couple_space_id}/{user_id}/{uuid}.{ext}`, so `(storage.foldername(name))[1]` is the space id and
`[2]` is the uploader's user id. Both the HarmonyOS client and the PWA upload with the user's
access token (not the anon key), so these policies apply to the `authenticated` role.

```sql
-- storage.objects already has RLS enabled on Supabase projects.

-- Members may upload only under a space they belong to, and only under their own {user_id} segment.
create policy "moments members can upload"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'moments'
  and public.is_space_member(((storage.foldername(name))[1])::uuid)
  and (storage.foldername(name))[2] = auth.uid()::text
);

-- Members may read any object in a space they belong to (both partners' photos).
create policy "moments members can read"
on storage.objects for select to authenticated
using (
  bucket_id = 'moments'
  and public.is_space_member(((storage.foldername(name))[1])::uuid)
);

-- Members may delete only objects under their own {user_id} segment.
create policy "moments owner can delete"
on storage.objects for delete to authenticated
using (
  bucket_id = 'moments'
  and public.is_space_member(((storage.foldername(name))[1])::uuid)
  and (storage.foldername(name))[2] = auth.uid()::text
);
```

Notes:

- These policies are the contract both clients depend on: the HarmonyOS client uploads sandbox
  photos here and stores the returned object path (not a public URL) in `moments.media_urls`,
  exactly like the PWA. Display always goes through a short-lived signed URL.
- The first path segment must be a real `couple_space_id` UUID; a malformed path would fail the
  `::uuid` cast and be rejected, which is the desired fail-closed behavior for a private bucket.
