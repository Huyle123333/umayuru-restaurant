# UMAYURU RESTAURANT — Bản đồ code: HUD và các cơ chế đặc biệt

Tài liệu tra cứu để mở đúng file, đúng dòng khi cần chỉ code — lúc bảo vệ, hoặc
lúc tự sửa sau này.

**Phạm vi**: toàn bộ giao diện trong màn chơi (HUD), cộng các cơ chế mà người
đọc code dễ hỏi "sao lại làm thế". Các hệ khác (menu, cốt truyện, lưu game) chỉ
xuất hiện ở Phần 2 khi liên quan.

**Số dòng đúng với commit ngày 24/9/2026.** Nếu đã sửa code sau đó, dùng tên hàm
để tìm (Ctrl+Shift+F trong Godot) thay vì tin số dòng.

**Quy ước**: `file.gd:120` = mở file đó, nhảy tới dòng 120.

---

## Phần 1 — Bảng tra cứu theo hệ thống

### 1.1 HUD tương tác — `scripts/interaction/interaction_hud.gd` (552 dòng)

Một `CanvasLayer` gom **bốn** khối không liên quan nhau. Dựng hoàn toàn bằng
code, không có file `.tscn`.

| Cần tìm | Ở đâu |
|---|---|
| Dựng toàn bộ giao diện | `:77` `_build_ui()` |
| Danh sách trạm trong tầm (góc dưới giữa) | `:525` `_redraw()` |
| Thanh thể lực | `:125` `_build_stamina_bar()`, cập nhật ở `:443` `_process()` |
| Ô kỹ năng + hiệu ứng xám khi chưa dùng được | `:179` `_build_skill_icon()`, `:287` `_on_skill_ready()` |
| Thanh tiến trình kỹ năng + chữ "3/5" | `:266` `_on_skill_progress()` |
| Bảng "trên bàn đang có gì" | `:307` `_build_table_note()`, `:470` `_redraw_table()` |
| Bảng đó **bám theo cái bàn** trong không gian | `:340` `_follow_table()` |
| Thông báo giữa màn ("Ghép xong: …") | `:400` `show_notice()` |
| Chữ "Đang cầm: …" | `:463` `_on_held_changed()` |
| Nối vào các hệ khác | `:255` skills, `:385` bếp, `:420` bộ chọn, `:424` đôi tay, `:458` bàn |
| Cỡ chữ, màu | `:19`–`:37` |
| Tầm hiện bảng bàn, độ cao neo, lề ngang | `:63`–`:67` (ba ô `@export`) |

**Vì sao bảng bàn bám theo bàn thay vì neo góc màn hình** — bếp có nhiều mặt
bàn; một bảng ở góc thì không nói được nó đang tả cái bàn nào. Chiếu vị trí bàn
ra toạ độ màn hình (`_follow_table()` dùng `cam.unproject_position()`) rồi đặt
bảng ngay bên phải nó thì câu hỏi "bàn nào" không tồn tại. Có kẹp trong khung
hình để bảng không trôi ra ngoài khi bàn ở sát mép.

---

### 1.2 Thanh tiến trình trên từng trạm — `scripts/ui/station_bars.gd` (172 dòng)

| Cần tìm | Ở đâu |
|---|---|
| Nối vào hệ bếp | `:79` `listen_to_cooking()` |
| Nhận tiến trình nấu | `:84` `_on_cooking()` |
| Nhận cảnh báo sắp cháy | `:91` `_on_burn_warning()` |
| Vẽ / cập nhật một thanh | `:98` `_set_bar()` |
| Xoá thanh khi mẻ xong | `:116` `_drop_bar()` |
| **Chiếu toạ độ 3D → 2D mỗi frame** | `:149` `_process()` |
| Kích thước, độ cao neo, màu, ngưỡng nháy | `:47`–`:62` |

**Vì sao là node RIÊNG chứ không nhét vào `interaction_hud`** — HUD kia đã 24 KB
và lo bốn thứ không liên quan nhau. Thanh trạm chỉ cần biết **hệ bếp** và
**camera**, không đụng gì tới bốn thứ đó, nên tách được sạch. Đây là lý do kiến
trúc, không phải sở thích: đổi cách vẽ thanh trạm không có cách nào làm hỏng
thanh thể lực.

**Cơ chế**: mỗi trạm đang nấu có một entry trong `_cells` (Dictionary
`trạm → {bar, fill, burning}`). Mỗi frame, `_process()` lấy `global_position` của
trạm, cộng `ANCHOR_HEIGHT` (`:52`, = 1.55 đơn vị), rồi
`camera.unproject_position()` ra toạ độ 2D. Không dùng `Sprite3D` vì thanh phải
giữ **đúng một cỡ pixel** bất kể xa gần.

---

### 1.3 Đồng hồ màn + tiền — `scripts/ui/hud_clock.gd` (242 dòng)

| Cần tìm | Ở đâu |
|---|---|
| Đếm ngược mỗi frame | `:124` `_process()` |
| Vẽ chữ đồng hồ (đổi màu khi gấp) | `:185` `_draw_clock()` |
| Vẽ số tiền | `:212` `_draw_money()` |
| Nhận tín hiệu tiền từ hệ khách | `:169` `listen_to_orders()`, `:174` `_on_money_changed()` |
| Đặt lại thời gian (cheat phím 0 dùng) | `:163` `set_time_left()` |
| Tín hiệu hết giờ | `:19` `signal time_up` |
| Thời lượng màn, bật/tắt đếm | `:36` `duration`, `:43` `counting_down` |
| Ngưỡng "sắp hết giờ" = 30 giây | `:33` `RUSH_THRESHOLD` |

---

### 1.4 Bảng đơn hàng — `scripts/ui/order_board.gd` (297 dòng)

| Cần tìm | Ở đâu |
|---|---|
| Dựng bảng | `:76` `_build_ui()` |
| Thêm / bỏ một vé | `:212` `add_order()`, `:227` `remove_order()` |
| Trượt ra / vào khi đóng mở | `:182` `set_open()` — vị trí đích tính ở `:154` `_x_open()` và `:158` `_x_closed()` |
| Phím tắt đóng mở | `:168` `_unhandled_key_input()` |
| Cái nhãn đếm số đơn khi bảng đóng | `:244` `_update_label()` |
| Đổi màu nhãn theo mức đầy | `:40`–`:42` |

### 1.5 Vé một đơn — `scripts/ui/order_ticket.gd` (273 dòng)

| Cần tìm | Ở đâu |
|---|---|
| Dựng một vé từ đối tượng đơn | `:68` `build()` |
| Thanh kiên nhẫn đổi màu | `:201` `_draw_bar()` |
| Số bàn (hoặc "—" khi còn xếp hàng) | `:180` `_draw_table_no()` |
| Trượt vào / ra | `:151` `slide_in()`, `:157` `slide_out()` |
| Ngưỡng vàng 50% / đỏ 20% | `:40`–`:41` |

**Ngưỡng vàng đặt đúng 50%** (`YELLOW_THRESHOLD`, `:40`) vì đó cũng là ngưỡng
tính "đơn hoàn hảo" — xem `scripts/restaurant/order.gd:` `PERFECT_THRESHOLD`.
Người chơi nhìn vé chuyển vàng là biết vừa mất tiền thưởng, không cần học thêm
con số nào.

---

### 1.6 Bảng chọn nguyên liệu — `scripts/interaction/picker_menu.gd` (231 dòng)

Bảng hiện ra ở tủ lạnh và máy kem (những trạm có nhiều lựa chọn).

| Cần tìm | Ở đâu |
|---|---|
| Mở với một trạm cụ thể | `:90` `open()` |
| Đóng | `:101` `close()` |
| Bắt phím W/S/E/C | `:121` `_input()` |
| Vẽ lại danh sách | `:154` `_redraw()` |
| Một dòng lựa chọn | `:178` `_build_row()` |
| Ô ảnh nguyên liệu | `:206` `_build_icon()` |
| Tín hiệu đã chọn | `:22` `signal item_chosen` |
| Tín hiệu mở/đóng (để khoá di chuyển) | `:24` `signal open_state_changed` |

**Bảng KHÔNG dừng game** — khách vẫn chờ trong lúc người chơi chọn. Nó chỉ khoá
di chuyển nhân vật, qua `open_state_changed` nối vào
`scenes/gameplay/level_base.gd:` `_lock_player()`.

---

### 1.7 Màn mở đầu (đếm ngược) — `scripts/ui/level_intro.gd` (128 dòng)

| Cần tìm | Ở đâu |
|---|---|
| Bắt đầu đếm ngược | `:53` `start_countdown()` |
| Đếm | `:63` `_process()` |
| Xong → phát tín hiệu | `:72` `_finish()`, `:30` `signal started` |
| Số giây đếm ngược | `:32` `COUNTDOWN_SECONDS` |

Đồng hồ màn và khách **chỉ được thả sau khi** `started` phát ra — xem
`level_base.gd:` `_build_level_intro()`.

### 1.8 Bảng kết quả — `scripts/ui/results_panel.gd` (285 dòng)

| Cần tìm | Ở đâu |
|---|---|
| Hiện bảng với số liệu màn | `:47` `show_results()` |
| Dựng nội dung | `:110` `_build_ui()` |
| Một dòng "nhãn — giá trị" | `:242` `_row()` |
| Chơi lại / về chọn màn | `:273` `_replay()`, `:278` `_go_level_select()` |
| Màu theo hạng S/A/B/C | `:22` `COLOR_GRADE` |

### 1.9 Hộp thoại trainer (màn hướng dẫn) — `scripts/ui/guide_panel.gd` (250 dòng)

| Cần tìm | Ở đâu |
|---|---|
| Đặt nội dung một bước | `:203` `set_step()` |
| Hỏi Có/Không | `:210` `ask()`, trả lời qua `:20` `signal start_choice` |
| Trượt hiện / ẩn | `:181` `open()`, `:188` `close()`, `:195` `_slide_to()` |

### 1.10 Menu hướng dẫn F1 — `scripts/ui/guide_menu.gd` (440) + `guide_content.gd` (169)

`guide_content.gd` là **dữ liệu thuần**, `guide_menu.gd` là phần vẽ.

| Cần tìm | Ở đâu |
|---|---|
| Nội dung các mục (sửa chữ ở đây) | `guide_content.gd:31` `SECTIONS` |
| Mở / đóng bằng F1 | `guide_menu.gd:54` `_unhandled_key_input()`, `:71` `toggle()` |
| Chọn một mục | `:219` `_select_section()` |
| Vẽ một khối nội dung | `:239` `_build_block()` |
| **Bảng công thức tự sinh** | `:336` `_add_recipe()`, `:353` `_recipe_row()` |
| Bảng mốc hạng S/A/B/C | `:408` `_add_grade_marks()` |

---

### 1.11 Bong bóng đơn + thanh kiên nhẫn trên đầu khách — `scripts/restaurant/customer.gd` (351 dòng)

Đây là phần HUD **nằm trong không gian 3D**, không thuộc `CanvasLayer` nào.

| Cần tìm | Ở đâu |
|---|---|
| Dựng bong bóng | `:222` `_build_bubble()` |
| Hiện / ẩn ảnh món | `:246` `show_order()`, `:258` `hide_order()` |
| Cập nhật thanh kiên nhẫn | `:268` `set_patience_bar()` |
| **Vẽ thanh bằng cách tô pixel** | `:274` `_draw_bar()` |
| Cỡ thanh, cỡ ảnh món, ba màu | `:199`–`:213` |

**Vì sao vẽ thanh bằng `Image.fill_rect` chứ không dùng `ProgressBar`** —
`ProgressBar` là `Control` (2D), muốn nó bám đầu một khách đang đi thì phải
chiếu toạ độ mỗi frame cho **từng khách**. Thay vào đó `_draw_bar()` tô trực
tiếp vào một ảnh rồi gán cho `Sprite3D` bật `billboard`: khách tự mang thanh
theo, engine lo chuyện quay mặt về camera, và chi phí chỉ là ghi lại một ảnh
nhỏ khi tỉ lệ đổi. Giải thích đầy đủ trong chú thích quanh `:192`.

---

## Phần 2 — Những cơ chế dễ bị hỏi "sao lại làm thế"

### 2.1 Chồng đồ ăn trên bàn chế tạo
`scripts/interaction/item_catalog.gd`

| Cần tìm | Ở đâu |
|---|---|
| Dựng cả chồng thành MỘT node | `:617` `make_stack()` |
| Bảng thông số từng món (`layout`) | `:606` `layout()`, dữ liệu trong `:54` `ITEMS` |
| Bước cao mỗi nấc | `:558` `STACK_STEP` |
| Tỉ lệ thu nhỏ | `:575` `STACK_SCALE` |
| Thứ tự xếp mặc định | `:579` `DEFAULT_ORDER` |
| Xoay mỗi tầng cho đỡ đơ | `:590` `ROTATION_PER_LAYER` |
| Những món làm ĐẾ (đĩa, nồi) | `:602` `BASE_ITEMS` |

**Câu trả lời ngắn**: mỗi món khai một bảng nhỏ `layout` gồm `order` (nấc thứ
mấy), `height` (dày bao nhiêu), `y` (lệch thêm để chữa model có tâm không nằm ở
đáy), `scale`. `make_stack()` sắp theo `order` rồi cộng dồn `height`. Bánh mì có
thêm `model_top` vì nắp bánh luôn đậy trên cùng cả chồng.

**Vì sao trả về một node duy nhất**: nơi gọi (`Workstation.show_stack()`) không
phải biết trên bàn có mấy món — nó vẫn giữ đúng một tham chiếu để xoá.

### 2.2 Bộ chọn mục tiêu dò va chạm thủ công
`scripts/interaction/target_picker.gd`

| Cần tìm | Ở đâu |
|---|---|
| Dựng danh sách ứng viên | `:95` `_build_candidates()` |
| **Truy vấn va chạm thủ công** | `:141` `_probe_collisions()` |
| Chọn mục tiêu nào | `:170` `_find_choice()` |
| Bắn tia từ giữa màn hình | `:268` `_pick_by_crosshair()` |
| Khoá mục tiêu bằng Tab | `:243` `_lock_choice()`, thời gian khoá `:49` |
| Tầm với (rộng × cao) | `:46`–`:47` |

**Vì sao không dùng `Area3D.get_overlapping_bodies()`** — đây là kết quả đo, không
phải sở thích: cùng một hình hộp, cùng vị trí, cùng `collision_mask`, truy vấn
thủ công tìm ra các trạm (`StaticBody3D`) còn danh sách của `Area3D` chỉ thấy
`CharacterBody3D` của nhân vật. Nguyên nhân: danh sách của `Area3D` được engine
dựng dần qua sự kiện vào/ra ở pha broadphase; với vật thể **tĩnh tuyệt đối** và
một `Area` tạo lúc chạy rồi bị cha kéo đi, cặp va chạm đó không phải lúc nào
cũng được đăng ký. Truy vấn trực tiếp không có bộ nhớ đệm — nó hỏi lại hình học
ngay tại frame này. Chú thích đầy đủ ngay trên `:141`.

### 2.3 Trạm dùng CHUỖI thay vì enum
`scripts/interaction/workstation.gd`

| Cần tìm | Ở đâu |
|---|---|
| Danh sách 13 loại trạm hợp lệ | `:63`–`:82` (chú thích) |
| Ô khai loại | `:83` `@export var kind` |
| Xử lý theo loại | `scripts/interaction/hands.gd:` `_on_interact()` — khối `match` |

**Vì sao chuỗi**: trạm được gán trực tiếp trong trình chỉnh scene, nên thêm một
loại mới chỉ cần gõ tên vào ô Inspector, không phải sửa script rồi build lại.
Đổi lại là gõ sai chính tả thì không ai báo — nên danh sách hợp lệ viết ngay
trên đầu ô `@export`.

### 2.4 Một node quản lý MỌI bếp
`scripts/interaction/cooking_system.gd`

| Cần tìm | Ở đâu |
|---|---|
| Đếm mọi mẻ đang nấu | `:104` `_process()` |
| Bỏ món lên trạm | `:204` `put_item()` |
| Lấy ra | `:218` `take_out()` |
| Mẻ xong | `:235` `_finish()` |
| Cháy | `:254` `_burn()`, mốc cháy `:161` `_burn_mark()` |
| Ba thời gian: nấu / nướng / thái | `:59`, `:65`, `:72` |
| Hệ số cháy | `:79` `burn_factor` |
| Kỹ năng bớt giây cháy | `:89` `burn_time_cut` |

**Vì sao một node chung chứ không mỗi bếp một script**: trạng thái "đang nấu"
nằm trong `_running` (Dictionary `trạm → {store, elapsed, mode, source_id, done}`).
Một node đếm hết thì thêm cái bếp thứ năm vào map không cần thêm dòng code nào,
và HUD chỉ phải nối **một** tín hiệu thay vì đi tìm từng bếp.

### 2.5 Luật màn theo chặng
`scripts/restaurant/level_rules.gd`

| Cần tìm | Ở đâu |
|---|---|
| Nhận luật và áp | `:68` `setup()` |
| Áp các số đặt một lần | `:89` `_apply_static()` |
| Theo dõi đồng hồ, sang chặng | `:129` `_process()` |
| Vào một chặng | `:154` `_go_to_stage()` |
| Đổi nhạc cao điểm | `:51` `PEAK_GROUP` |
| **Bảng luật Ngày 1** | `autoload/game_data.gd:125` `RULES_D1` |
| Đọc luật của một màn | `autoload/game_data.gd:770` `rules_for_level()` |

**Vì sao tách khỏi `customer_manager`**: file đó giữ luật **của nhà hàng** (khách
đến thì ngồi, hết kiên nhẫn thì đi) — đúng với mọi màn. Còn "Ngày 1 có 6 khách,
3 bàn, thực đơn 6 món" là luật **của một màn**. Trộn hai thứ thì thêm Ngày 4 phải
sửa file cơ chế. Tách ra thì Ngày 4 chỉ là thêm một bảng dữ liệu vào `game_data`.

⚠ **Khoá hai bên phải trùng nhau.** `_rules["max_customers"]` ở đây phải khớp
khoá trong `RULES_D1`. Không khớp thì `.has()` trả false và **toàn bộ luật màn
lặng lẽ không được áp** — Ngày 1 chạy bằng số mặc định, không một dòng cảnh báo.
Lỗi này đã xảy ra thật ngày 19/9/2026. Chú thích cảnh báo ở `:85`.

### 2.6 Công tắc mở/khoá một nhánh cơ chế
`scripts/interaction/item_catalog.gd`

| Cần tìm | Ở đâu |
|---|---|
| Công tắc nồi | `:291` `POT_ENABLED` |
| Những id chỉ tồn tại khi có nồi | `:295` `POT_LOCKED_ITEMS` |
| Hàm hỏi "id này có bị khoá không" | `:310` `is_locked()` |
| Giấu vật bị khoá khỏi map lúc chạy | `scenes/gameplay/level_base.gd:` `_reveal_map_items()` |

Đổi `POT_ENABLED` thành `false` là: thực đơn tự bỏ ba món nấu nồi, khách thôi
gọi chúng, cái nồi biến khỏi map, và trang hướng dẫn tự bỏ luôn ba công thức đó
— **không phải sửa chỗ nào khác**. Đây là ví dụ tốt để nói về tách dữ liệu khỏi
cơ chế.

### 2.7 Trang hướng dẫn tự sinh từ bảng công thức
`scripts/ui/guide_menu.gd:336` `_add_recipe()` ← `item_catalog.TABLE_RECIPES` / `OVEN_RECIPES`

**Vì sao không gõ tay danh sách món vào trang hướng dẫn**: công thức là thứ đổi
nhiều nhất trong cả game. Gõ tay thì trang hướng dẫn nói sai ngay lần sửa công
thức đầu tiên, mà nó sai **im lặng** — không có lỗi nào báo, chỉ có người chơi
làm theo rồi không ra món. Sinh thẳng từ `ItemCatalog` thì trang này không bao
giờ lệch được với luật thật. Nó cũng tự lọc món đang bị khoá qua `is_locked()`.

### 2.8 Navmesh nướng lúc chạy
`scripts/restaurant/customer_manager.gd`

| Cần tìm | Ở đâu |
|---|---|
| Nướng navmesh | `:255` `_bake_navmesh()` |
| **Đo độ lệch cao của navmesh** | `:330` `_measure_height_offset()` |
| Nhóm nguồn hình học | `:233` `SOURCE_GROUP` |
| Lớp va chạm riêng cho tấm chắn | `:237` `NAV_BLOCK_LAYER` |
| Hai tấm chắn lối vào bếp | `:241` `BLOCKERS` |

**Hai vùng chứ không một** vì khu khách hình chữ L: một khung bao chỉ vẽ được
hình hộp, mà hộp trùm cả chữ L thì trùm luôn cả bếp — khách sẽ đi thẳng vào bếp.
Hai hộp chạm nhau dọc cạnh z=12, Godot tự nối chúng ở cạnh chung.

**Độ lệch cao ĐO lúc chạy chứ không gõ tay** (`:330`): con số này do Recast quyết
theo `cell_height` và chiều dày hình va chạm sàn — đổi một trong hai là nó đổi
theo. Gõ tay thì một ngày nào đó khách sẽ lún xuống sàn hoặc bay lơ lửng.

### 2.9 Di trú file save khi đổi tên khoá
`autoload/game_data.gd`

| Cần tìm | Ở đâu |
|---|---|
| Ghi ra Dictionary | `:988` `to_dict()` |
| **Đọc vào, có đọc lùi khoá cũ** | `:1010` `from_dict()` |
| Ghi một lượt vào bảng xếp hạng | `:631` `record_rank()` |

File save nằm ở `user://savegame.json` trên máy người chơi — **ngoài repo, ngoài
tầm với của git**. Đổi tên khoá mà không đọc lùi thì mọi tiến độ biến mất im
lặng: game vẫn chạy, chỉ là màn khoá lại và nhân vật đã mở đóng lại. Nên
`from_dict()` đọc khoá tiếng Anh trước, không có thì đọc khoá tiếng Việt cũ:

```gdscript
infinite_skill = bool(data.get("infinite_skill", data.get("ki_nang_vo_han", false)))
```

Lần ghi kế tiếp tự động ghi bằng khoá mới, nên nhánh cũ chỉ chạy đúng một lần
cho mỗi file save.

### 2.10 Cheat tua giờ (phím 0)
`scenes/gameplay/level_base.gd`

| Cần tìm | Ở đâu |
|---|---|
| Bắt phím | `:448` `_skip_time()` |
| Kéo đồng hồ về 210 giây | `:28` `SKIP_SECONDS` |

**Vì sao 210 chứ không 212**: 212 đúng là mốc đổi sang nhạc cao điểm, mà
`level_rules` so bằng `time_left <= music_cue`. Đặt đúng 212,0 thì kết quả phụ
thuộc frame nào chạy trước — tua xong có thể vẫn còn 212,0 chẵn và nhạc chưa
đổi. 210 là ĐÃ VƯỢT mốc nên nhạc chắc chắn đổi ngay frame kế tiếp.

---

## Phần 3 — Câu hội đồng có thể hỏi → mở ở đâu

| Câu hỏi | Mở |
|---|---|
| "Thanh tiến trình trên trạm làm thế nào?" | `station_bars.gd:149` `_process()` — chiếu 3D→2D mỗi frame. Nói thêm §1.2 vì sao tách node riêng. |
| "Sao thanh đó không phải Sprite3D?" | §1.2 — phải giữ đúng một cỡ pixel bất kể xa gần. |
| "Thanh kiên nhẫn trên đầu khách thì sao?" | `customer.gd:274` `_draw_bar()` — tô pixel vào ảnh + `Sprite3D` billboard. §1.11. |
| "Vì sao hai thanh làm hai kiểu khác nhau?" | Một cái bám **trạm tĩnh** (chiếu toạ độ rẻ), một cái bám **khách đang đi** và có nhiều khách cùng lúc (billboard rẻ hơn). §1.2 + §1.11. |
| "HUD gồm những gì?" | `interaction_hud.gd:77` `_build_ui()` — bốn khối, xem bảng §1.1. |
| "Bảng 'trên bàn có gì' sao bám theo bàn?" | `interaction_hud.gd:340` `_follow_table()`. §1.1. |
| "Vé đơn hàng đổi màu theo gì?" | `order_ticket.gd:201` `_draw_bar()`, ngưỡng ở `:40`–`:41`. §1.5. |
| "Sao ngưỡng vàng là 50%?" | §1.5 — trùng ngưỡng đơn hoàn hảo, người chơi chỉ phải học một con số. |
| "Đồng hồ đổi màu khi nào?" | `hud_clock.gd:185` `_draw_clock()`, ngưỡng `:33`. |
| "Bảng chọn nguyên liệu có dừng game không?" | Không. `picker_menu.gd:24` `open_state_changed` → chỉ khoá di chuyển. §1.6. |
| "Chồng đồ ăn trên bàn xếp thế nào?" | `item_catalog.gd:617` `make_stack()` + bảng `layout` ở `:606`. §2.1. |
| "Sao phải có ô `y` riêng cho từng món?" | §2.1 — nhiều model KayKit có tâm không nằm ở đáy. |
| "Chọn mục tiêu khi đứng giữa nhiều trạm?" | `target_picker.gd:170` `_find_choice()`, Tab khoá ở `:243`. |
| "Sao không dùng Area3D có sẵn?" | `target_picker.gd:141` — đọc chú thích ngay trên hàm. §2.2. |
| "Sao loại trạm là chuỗi mà không phải enum?" | `workstation.gd:63`–`:83`. §2.3. |
| "Nhiều bếp thì quản lý ra sao?" | `cooking_system.gd:104` `_process()` + `_running`. §2.4. |
| "Ngày 2 khó hơn Ngày 1 ở đâu?" | `game_data.gd:125` `RULES_D1` (bảng dữ liệu) + `level_rules.gd:154` `_go_to_stage()`. §2.5. |
| "Sao tách luật màn khỏi hệ khách?" | §2.5. |
| "Trang hướng dẫn có tự cập nhật khi đổi công thức?" | Có. `guide_menu.gd:336` `_add_recipe()`. §2.7. |
| "Tắt cơ chế nồi thì phải sửa mấy chỗ?" | Một chỗ: `item_catalog.gd:291` `POT_ENABLED`. §2.6. |
| "Khách tìm đường thế nào?" | `customer_manager.gd:255` `_bake_navmesh()`. §2.8. |
| "Sao phải hai vùng navmesh?" | §2.8 — khu khách hình chữ L. |
| "Đổi tên khoá thì save cũ có mất không?" | Không. `game_data.gd:1010` `from_dict()`. §2.9. |
| "Vì sao cheat tua về 210 mà không 212?" | `level_base.gd:28` `SKIP_SECONDS`. §2.10. |
| "Giao diện dựng bằng code hay `.tscn`?" | HUD trong màn chơi: **code** (`interaction_hud`, `station_bars`, `hud_clock`, `order_board`, `picker_menu`). Menu ngoài: **`.tscn`** trong `scenes/menu/`. Lý do: HUD phải dựng lại tuỳ màn và tuỳ nhân vật, còn menu thì cố định. |

---

## Phần 4 — Sơ đồ ai nối vào ai

Mọi thứ trong màn chơi do `scenes/gameplay/level_base.gd` dựng lúc chạy:

```
level_base._build_interaction()        :112
├── TargetPicker        (gắn vào nhân vật)
├── InteractionHUD  ←── nghe TargetPicker, Hands, CookingSystem, Workstation
├── Hands               (gắn vào nhân vật)
├── CookingSystem   ──→ StationBars, InteractionHUD
├── StationBars     ←── nghe CookingSystem
├── PickerMenu      ←──→ Hands (xin mở / trả lựa chọn)
└── SkillManager

level_base._build_order_hud()          :274
├── OrderBoard      ←── nghe CustomerManager
└── HudClock        ←── nghe CustomerManager (tiền)

level_base._apply_level_rules()        :326
└── LevelRules      ──→ vặn các núm của CustomerManager theo đồng hồ
```

**Dùng `load()` lúc chạy chứ không `preload`**: `preload` và `class_name` được
phân giải lúc **biên dịch**. Nếu một script của hệ tương tác có lỗi cú pháp thì
chính `level_base.gd` cũng không biên dịch được — mà nó là script gốc của mọi
màn chơi, nên cả map không load và màn hình trắng trơn, không có gì để lần ra
nguyên nhân. Với `load()` thì lỗi ở hệ tương tác chỉ làm mất HUD, map vẫn chạy
và console in ra đúng file hỏng. Chú thích ở `level_base.gd:105`.

---

## Phụ lục — Một họ lỗi đáng nói trong báo cáo

Khi đổi toàn bộ định danh của dự án từ tiếng Việt sang tiếng Anh (9 lô, tháng
9/2026), **mọi lỗi nghiêm trọng đều thuộc đúng một họ**: tên định danh sống bên
trong một chuỗi, nơi trình biên dịch không nhìn thấy. Sáu biến thể đã gặp:

| Dạng | Ví dụ | Hỏng thế nào |
|---|---|---|
| Khoá âm thanh | `AmThanh.play_sfx("hoan_hao")` | im lặng — mất tiếng |
| Tên tín hiệu | `has_signal("noi_dung_thay_doi")` | im lặng — không nối được |
| Tên thuộc tính | `n.get("loai")` | im lặng — trả về null |
| Kiểm tra thuộc tính | `"khoa_di_chuyen" in obj` | im lặng — điều kiện luôn false |
| Tên node | `get_node("TayCam")` | im lặng — trả về null |
| Đường dẫn tài nguyên | `preload("res://.../khach.tscn")` | **báo lỗi to** — cả file không biên dịch |

Chỉ dạng cuối tự báo. Năm dạng còn lại phải tự đi tìm. Cách chặn đã dùng: sau
mỗi lô, liệt kê **mọi chuỗi** trong các file vừa sửa và đối chiếu với thứ chúng
trỏ tới — file có tồn tại không, tín hiệu có tên đó không, node có trong scene
không.

Một lỗi thứ hai đáng nói vì nó **có** cảnh báo: đổi tham số thành tên trùng với
biến thành viên của lớp làm câu gán `order = order` tự gán chính nó, và biến
thành viên không bao giờ được đặt. Godot cảnh báo
`"order" is shadowing an already-declared variable` — đây là lần duy nhất trong
cả chiến dịch trình biên dịch bắt được một lỗi đổi tên, vì nó đụng vào **phạm vi
biến**, thứ mà trình biên dịch thật sự hiểu.
