-- ====================================================================
-- OUR SPACE - SUPABASE VERİTABANI & STORAGE KURULUM REHBERİ
-- ====================================================================

-- 1. Anılar & Fotoğraflar Tablosu (moments)
create table if not exists moments (
  id bigint primary key generated always as identity,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  note text,
  image_url text not null
);

-- 2. Canlı Mesajlaşma Tablosu (messages)
create table if not exists messages (
  id bigint primary key generated always as identity,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  content text not null,
  sender_name text not null
);

-- 3. Ortak Dilekler ve Planlar Tablosu (shared_plans)
create table if not exists shared_plans (
  id bigint primary key generated always as identity,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  is_done boolean default false not null
);

-- ====================================================================
-- REALTIME (Canlı Dinleme) AKTİF ETME
-- ====================================================================
-- Supabase .stream() özelliğinin yeni veri eklenince anında tetiklenmesi için:
alter publication supabase_realtime add table moments;
alter publication supabase_realtime add table messages;
alter publication supabase_realtime add table shared_plans;

-- ====================================================================
-- RLS (Row Level Security) İZİNLERİ
-- ====================================================================
alter table moments enable row level security;
alter table messages enable row level security;
alter table shared_plans enable row level security;

-- Anonim key ile okuma, ekleme, güncelleme ve silme politikaları
create policy "Anonim kullanıcılar anıları yönetebilir"
  on moments for all using (true) with check (true);

create policy "Anonim kullanıcılar mesajları yönetebilir"
  on messages for all using (true) with check (true);

create policy "Anonim kullanıcılar planları yönetebilir"
  on shared_plans for all using (true) with check (true);

-- ====================================================================
-- STORAGE (Depolama) AYARI
-- ====================================================================
-- Not: Supabase Storage > 'New Bucket' sekmesinden adı 'photos' olan
-- ve 'Public' olarak işaretlenmiş bir bucket oluşturmayı unutmayın.
-- Eğer SQL ile oluşturmak isterseniz:
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do update set public = true;

-- Storage için okuma, yükleme ve silme politikaları
create policy "Photos bucket public erişim"
  on storage.objects for select using (bucket_id = 'photos');

create policy "Photos bucket public yükleme"
  on storage.objects for insert with check (bucket_id = 'photos');

create policy "Photos bucket public silme"
  on storage.objects for delete using (bucket_id = 'photos');
