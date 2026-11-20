---
name: turkce-yazim
description: Use whenever Claude writes or translates Turkish that another person will read on the user's behalf (emails, messages, comments, replies, short notes, English to Turkish translation). Makes the text read as typed by a native Turkish professional, not translated from English, and applies sen/siz address and truthfulness rules. Not for ordinary Turkish chat replies to the user.
---

# Türkçe Yazım

Reader: a Turkish professional. Pass mark: they feel a person typed it, not a translation.

## How to write
1. Say it first the way you would say it to that person on the phone, in full sentences. Then check the lists below and fix only what they catch.
2. A length limit is met by dropping a fact, never by clipping grammar ("Raporu bitirdim. Görüşelim." reads as a bot).
3. Add nothing to fill space: no extra facts, no general claims the writer cannot back, no lesson at the end.

## Önce: okuyan Türk mü?
Write Turkish only to a reader confirmed Turkish (stated language, then location, then name). Everyone else gets English. A Turkish text sent to a non-Turkish reader is a heavy penalty.

## Hitap
When the request names the form (sen or siz), use it. Otherwise:
- Bare first name means **sen**, all the way through ("Merhaba Evren, konuşmanı gördüm"). Never a bare name with siz forms ("Merhaba Evren, konuşmanızı").
- **Siz** only with Bey/Hanım, only for an older reader, only in a Turkey context. Bey/Hanım only when the gender is known: the person states pronouns, their own earlier message shows it, or the name is unambiguous (Ayşe, Mehmet). Evren and Deniz stay unknown. Siz with the gender unknown: full name plus siz ("Merhaba Deniz Kaya, yazınızı okudum").

## Doğruluk
- Every claim about the writer is true today and comes from the facts given, not inferred from them. Keep the role the facts give: someone who supported an analysis is "analize destek verdim", not "analizi yönettim". A team's work is "ekibimizle ... hazırladık", never "ben hazırladım". Past roles stay in the past tense. No "ben de" / "biz de" unless the writer really did the same thing.
- A reply answers every part of the question. Never defer ("ayrıca yazarım"), never hedge ("sanırım", "düşünüyorum") where the writer has the proof. A part the given facts do not cover gets a placeholder "[yazar: ...]" for the writer to fill, not an invented answer and not silence.

## Çeviri kokusu
- The verb fits the object: a talk is "gördüm" or "izledim", a post is "okudum" or "... yazmışsınız", both together "ilgimi çekti". One finite verb beats a stack of -ması/-manız nouns ("bırakmasını yazmanız ilgimi çekti" is three nouns deep; say "yazmışsınız, çok yerinde"). A model is "yayımlandı"; a feature or tool "yayına alındı" or "çıkardık"; a product "geliştirilir", not "yapılır".
- Words: internal tool is "şirket içi araç", never "iç araç". Myth is "mit" or "yanlış bilinenler", not "efsane". Keep the English Turkish tech people actually say (AI, PM, LLM, eval, RAG, benchmark); drop the rest (squad, feature, deliver etmek, aksiyon almak).
- Calques, do not write: sahip olmak for "have", -lı bir şekilde, değer katmak, mümkün hale gelmek, deneyimimizde ("bizde"), -meye değer, hak ediyor, "Güven ... geldi" (say "güveni ... kazandık"), "bu durum" as a stand-in for "this".
- "X değil, Y" at most once per text, and never split into "X değil. Y." as two sentences.
- Subject pronoun (Ben, Biz) only for real contrast with the reader. No -mektedir/-maktadır. No openers like Ayrıca, Bu bağlamda, Söz konusu. Embedded questions take -dığını / -acağını ("nasıl baktığını"), not a noun ("bakışını"). The accusative only on a definite object ("dört aracı" needs a known four).
- A sentence may start with Ama or Çünkü.

## Son kontrol
Read it once as the reader. Any phrase that sounds like a subtitle gets said again in phone words.
