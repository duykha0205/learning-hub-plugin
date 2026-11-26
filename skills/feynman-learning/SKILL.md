---
name: feynman-learning
description: Design multi-angle Feynman checks, SM-2 spaced repetition, active recall, and interleaved practice inside HTML artifacts; every attempt is a HUB_EXERCISE_SUBMIT.
---

# Feynman & Learning-Science Runbook

Áp dụng khi thiết kế bài học, bài kiểm tra Feynman, deck ôn tập hoặc drill-down artifact. Kết hợp với `chinese-tutor` (nhịp 15 phút) và `memory-consolidator` (dọn trí nhớ).

## 1. Bốn góc Feynman (`<hub-feynman-note>`)

Mỗi concept xoay vòng 4 facet, **không lặp cùng một facet hai lần liên tiếp**; ghi facet vừa dùng vào `04-digests` để buổi sau đổi góc.

| `facet` | Dùng khi | Câu hỏi mẫu |
| :--- | :--- | :--- |
| `explain_simple` | Người học vừa tiếp thu khái niệm mới, cần kiểm tra hiểu bản chất. | "Giải thích 4 thanh điệu bằng lời của bạn, không dùng thuật ngữ." |
| `contrast_analogy` | Khái niệm dễ lẫn với kiến thức đã biết; cần phân biệt cặp gần nhau. | "So sánh thanh 3 `214` với dấu hỏi tiếng Việt; chỗ nào khác?" |
| `apply_scenario` | Đã có nền cơ bản; cần chuyển kiến thức sang tình huống thật. | "Đặt câu gọi món dùng 想 / 要 và thanh điệu đúng." |
| `spot_the_bug` | Củng cố phát hiện lỗi; người học đã quen dạng đúng. | "Câu này sai ở đâu: `nǐ hảo` (Pinyin + thanh)?" |

Cú pháp chuẩn:

```html
<hub-feynman-note
  facet="explain_simple"
  concept-key="zh:tone-3"
  prompt="Giải thích thanh 3 (214) bằng lời của bạn">
</hub-feynman-note>
```

`<hub-feynman-note>` **chỉ thu input** (facet, concept-key, prompt, hint, textarea); nó không có nút nộp và không tự phát message. Mỗi trang ghép nó với **một** `<hub-exercise-submit>` cấp trang: nút đó gom `<hub-quiz-check>` + `[data-question]` + mọi Feynman note thành một `HUB_EXERCISE_SUBMIT` (`answers` + `feynmanNotes`). Ghi nhận được lưu nguyên văn vào `session_events` + `exercise_submissions` (dòng Feynman có `score: 0, maxScore: 0` = "Chưa chấm" cho tới khi tutor chấm qua `submit_feynman_assessment`).

## 2. Spaced Repetition (SM-2)

| Từ khóa | Ý nghĩa |
| :--- | :--- |
| `SM-2` | Server tính `ease_factor`, `interval_days`, `repetitions`, `next_review_at` từ quality `0..3`. Tutor **không bao giờ** tự tính. |
| `dueSrsCards` | Thẻ đến hạn trong `get_domain_context`; nạp thẳng vào `<hub-review-deck>`. |
| `<hub-review-deck>` | Deck tự chấm mức nhớ; phát `HUB_LOG_REVIEW` để cập nhật `srs_cards`. |
| Grade `0..3` | `0` quên sạch, `1` nhớ mảnh, `2` nhớ rõ có ví dụ, `3` thuần thục. |

- Thẻ trễ hạn hoặc grade `0..1` → hạ interval; grade `2..3` → giãn bình thường.
- Sau mỗi buổi, gọi `submit_feynman_assessment` cho phần Feynman để SM-2 cộng hưởng (score thấp → ôn sớm hơn).

## 3. Active Recall

- Hỏi **trước**, đáp án hiện **sau** khi người học trả lời. Không render đáp án sẵn trong DOM/`prompt` của câu hỏi.
- Dùng `<hub-quiz-check>` với `options` + `correct-id`; Tutor chỉ giải thích sau khi component báo `HUB_LOG_QUIZ`.
- Feynman note luôn là câu hỏi mở: gợi ý (`hint`) chỉ gợi hướng, không chứa câu trả lời.

## 4. Interleaving

- Trộn **2–3 concept liên quan** trong một deck/buổi (ví dụ thanh 3 + sandhi + bộ thủ cùng chủ đề), không dồn một concept dạng khối.
- Xen **cũ + mới**: mỗi artifact Layer 2+ có ít nhất 1 câu từ buổi trước và 1 câu của bài hôm nay.
- Đổi dạng bài giữa các concept (quiz → Feynman → scenario) để tránh học máy móc.

## 5. Nộp bài: một đường duy nhất

- Mọi bài nộp (exercise, quiz, Feynman) đều là `HUB_EXERCISE_SUBMIT`; Feynman đi kèm `feynmanNotes` (`facet`, `conceptKey`, `prompt`, `answerText`) trong cùng message với `answers`.
- `<hub-exercise-submit>` — một nút mỗi trang, nhãn mặc định "Gửi bài" — gom `<hub-quiz-check>`, `[data-question]` và mọi `<hub-feynman-note>` rồi phát message qua `HubBridge`; host gọi `POST /api/sessions/[sessionId]/events` (shell) hoặc `app_save_selection` (MCP App).
- `processInboundSessionEvent` ghi `session_events` + `exercise_submissions` trong **cùng transaction**. Tutor chỉ đọc qua `get_session_inbox(sessionId)`; **không tự INSERT** vào DB.
- `HUB_FEYNMAN_SUBMIT` chỉ còn là loại legacy được chấp nhận để đọc artifact cũ; không phát nó từ bài mới.

## 6. Đóng vòng lặp: `<exercise-history>`

Luôn kết thúc artifact bài học bằng lịch sử nộp bài để người học thấy tiến bộ:

```html
<exercise-history limit="5"></exercise-history>
```

- Tự gọi `GET /api/exercises/overview` (10 dòng mặc định, đổi bằng `limit`) khi mount và **refresh ngay khi POST xong** (`hub:exercise-saved`), với `HUB_EXERCISE_SUBMIT` làm fallback.
- Attribute tùy chọn: `user-id`, `domain-id`, `session-id`, `artifact-id`, `limit`, `month` (`YYYY-MM`), `title`, `api-base`. Trong `/s/{sessionId}` và `/<user>/<domain>/...` không cần khai báo gì thêm; `api-base` chỉ dành cho host MCP App (host tự inject `<meta name="hub-api-base">`).
- Không tự fetch trong HTML artifact (policy cấm `fetch(`); component lo toàn bộ.
