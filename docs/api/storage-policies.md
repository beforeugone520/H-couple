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
