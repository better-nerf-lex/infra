-- Development-Only Seed Data
-- This file contains test data for local/dev environments
-- IMPORTANT: This should NOT be run in production

-- Document examples (templates for document generation)
INSERT INTO document_examples (id, title, description, questions, base, requirements, template_files)
VALUES
    ('11111111-1111-1111-1111-111111111111',
     'Pozew o rozwód (z alimentami)',
     'Pozew o rozwód zawierający wnioski o uregulowanie władzy rodzicielskiej i alimentów na dzieci.',
     '[
        {"id":"plaintiff","text":"Kto składa pozew rozwodowy?","type":"ENTITY"},
        {"id":"defendant","text":"Kim jest drugi małżonek?","type":"ENTITY"},
        {"id":"marriage_date","text":"Data zawarcia małżeństwa","type":"TEXT"},
        {"id":"marriage_place","text":"Miejsce zawarcia małżeństwa","type":"TEXT"},
        {"id":"children_count","text":"Liczba małoletnich dzieci stron","type":"TEXT"},
        {"id":"children_details","text":"Dane dzieci (imiona, daty urodzenia)","type":"TEXT"},
        {"id":"alimony_amount","text":"Wnioskowana kwota alimentów na każde dziecko","type":"TEXT"},
        {"id":"custody_request","text":"Wniosek dotyczący władzy rodzicielskiej","type":"TEXT"},
        {"id":"fault","text":"Czy rozwód z orzekaniem o winie?","type":"TEXT"},
        {"id":"separation_date","text":"Kiedy nastąpił zupełny i trwały rozkład pożycia?","type":"TEXT"}
      ]'::jsonb,
     '["eli/MP/1964/155/ogl", "eli/MP/1964/155/ogl"]'::jsonb,
    '["Odpis aktu małżeństwa", "Odpisy aktów urodzenia dzieci", "Zaświadczenie o zarobkach"]'::jsonb,
     '[
        {"id":"t1111111-1111-1111-1111-111111111111","name":"pozew_rozwod_alimenty.pdf","s3Key":"templates/document-examples/11111111-1111-1111-1111-111111111111/pozew_rozwod_alimenty.pdf"}
      ]'::jsonb),

    ('22222222-2222-2222-2222-222222222222',
     'Pozew o rozwód (bez dzieci)',
     'Pozew o rozwód w sytuacji, gdy małżonkowie nie posiadają wspólnych małoletnich dzieci.',
     '[
        {"id":"plaintiff","text":"Dane powoda/powódki","type":"ENTITY"},
        {"id":"defendant","text":"Dane pozwanego/pozwanej","type":"ENTITY"},
        {"id":"marriage_date","text":"Data zawarcia związku małżeńskiego","type":"TEXT"},
        {"id":"marriage_place","text":"Miejsce sporządzenia aktu małżeństwa","type":"TEXT"},
        {"id":"separation_date","text":"Data ustania wspólnego pożycia","type":"TEXT"},
        {"id":"fault","text":"Czy żądasz orzekania o winie małżonka?","type":"TEXT"},
        {"id":"property_division","text":"Czy składasz wniosek o podział majątku wspólnego?","type":"TEXT"},
        {"id":"maintenance_request","text":"Czy żądasz alimentów na swoją rzecz od małżonka?","type":"TEXT"},
        {"id":"reasons","text":"Główne przyczyny rozkładu pożycia","type":"TEXT"},
        {"id":"witnesses","text":"Dane świadków (jeśli dotyczy)","type":"TEXT"}
      ]'::jsonb,
     '["eli/MP/1964/155/ogl", "eli/MP/1964/155/ogl"]'::jsonb,
     '["Skrócony odpis aktu małżeństwa"]'::jsonb,
     '[
        {"id":"t2222222-2222-2222-2222-222222222222","name":"pozew_rozwod_bez-dzieci.pdf","s3Key":"templates/document-examples/22222222-2222-2222-2222-222222222222/pozew_rozwod_bez-dzieci.pdf"}
      ]'::jsonb),

    ('33333333-3333-3333-3333-333333333333',
     'Ponaglenie płatności',
     'Formalne wezwanie do zapłaty zaległego zobowiązania.',
     '[
        {"id":"creditor","text":"Kto jest wierzycielem?","type":"ENTITY"},
        {"id":"debtor","text":"Kto jest dłużnikiem?","type":"ENTITY"},
        {"id":"amount","text":"Kwota zaległego zobowiązania","type":"TEXT"},
        {"id":"currency","text":"Waluta zadłużenia","type":"TEXT"},
        {"id":"invoice_number","text":"Numer faktury lub umowy","type":"TEXT"},
        {"id":"due_date","text":"Pierwotny termin płatności","type":"TEXT"},
        {"id":"delay_days","text":"Liczba dni opóźnienia w płatności","type":"TEXT"},
        {"id":"interest","text":"Czy naliczane są odsetki ustawowe?","type":"TEXT"},
        {"id":"payment_method","text":"Preferowany sposób dokonania płatności","type":"TEXT"},
        {"id":"deadline","text":"Ostateczny termin zapłaty","type":"TEXT"}
      ]'::jsonb,
     '["eli/MP/1964/155/ogl"]'::jsonb,
     '["Kopia faktury", "Kopia umowy"]'::jsonb,
     '[
        {"id":"t3333333-3333-3333-3333-333333333331","name":"payment_reminder_template_1.pdf","s3Key":"templates/document-examples/33333333-3333-3333-3333-333333333333/t3333333-3333-3333-3333-333333333331.pdf"},
        {"id":"t3333333-3333-3333-3333-333333333332","name":"payment_reminder_template_2.pdf","s3Key":"templates/document-examples/33333333-3333-3333-3333-333333333333/t3333333-3333-3333-3333-333333333332.pdf"}
      ]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Test user
