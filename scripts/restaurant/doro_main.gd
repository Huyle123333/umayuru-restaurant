extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  BẢNG SỐ CHỈNH CỦA DORO — sửa ở ĐÂY, không sửa trong doro_pet.gd     ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## File này KHÔNG có một dòng logic nào. Nó chỉ là chỗ đặt những patience_left số quyết
## định Doro trông và cư xử ra sao.
##
## Vì sao tách khỏi doro_pet.gd: chỉnh cho vừa mắt là việc phải làm ĐI LÀM LẠI
## — chạy game, nhìn, đổi số, chạy lại, có khi mười lượt mới ưng. Mỗi lượt như
## thế mà phải mở một file 250 dòng rồi dò tìm giữa đống code thì dễ sửa nhầm,
## và lịch sử git về sau lẫn lộn giữa "đổi số cho đẹp" với "sửa cách nó chạy".
## Một file chỉ có số thì mở ra là thấy ngay, và mọi thay đổi trong nó đều
## thuộc đúng một loại.
##
## ─────────────────────────────────────────────────── CÁCH CHỈNH
##
##   1. Sửa số ở dưới rồi LƯU file.
##   2. Chạy lại game (F5). Không phải nhập lại gì, không phải mở lại Godot.
##
## Số nào cũng sửa được độc lập, trừ BASE_HEIGHT — xem giải thích ngay dưới.


# ════════════════════════════════════════════════════════ KÍCH THƯỚC ════════

## ► CHIỀU HEIGHT CỦA DORO TRONG GAME, tính bằng MÉT. Đây là patience_left số bạn muốn sửa.
##
## Vài mốc để so:
##     0,60   ngang cái thùng rác, tới đầu gối nhân vật
##     0,90   tới ngang hông  ← đang dùng
##     1,20   tới ngang ngực
##     1,76   đúng bằng nhân vật người chơi
##     2,12   nguyên cỡ model gốc
##
## Đổi số này là ĐỦ. Hộp va chạm, điểm gắn nhãn tên và cú nảy lúc được cho đồ
## đều tự tính lại theo nó — không có chỗ nào phải sửa kèm.
const HEIGHT := 0.9

## Chiều cao MODEL GỐC, đo trong Blender (hộp bao thế giới, trục Z = 2,115).
##
## ĐỪNG đổi số này để chỉnh to nhỏ — nó không phải nút chỉnh, nó là một PHÉP
## ĐO. Doro co lại theo tỉ lệ HEIGHT / BASE_HEIGHT, nên sửa mẫu số cũng làm Doro to
## nhỏ, nhưng sai về mặt ý nghĩa: lần sau ai đọc file sẽ tưởng model gốc cao
## chừng đó thật.
##
## Chỉ đổi khi THAY MODEL KHÁC, và khi đó phải đo lại trong Blender chứ không
## đoán.
const BASE_HEIGHT := 2.115

## Cạnh hộp va chạm theo chiều ngang, tính theo phần trăm chiều cao.
##
## 1,15 = hộp rộng hơn Doro cao một chút. Rộng hơn thân thật là CỐ Ý: hộp này
## chỉ dùng để bấm trúng (Doro không va chạm với ai), mà một mục tiêu đang đi
## qua đi lại thì hộp rộng dễ nhắm hơn hẳn. Rộng quá thì bấm trúng Doro cả khi
## đang nhắm cái bếp phía sau nó.
const BOX_WIDTH := 1.15


# ══════════════════════════════════════════════════════ DI CHUYỂN ═══════════

## Tốc độ đi, mét mỗi giây. Nhân vật người chơi đi 6,4 — Doro chậm hơn nhiều
## là đúng, nó đang đi dạo chứ không chạy việc.
const SPEED := 1.4

## Tốc độ xoay người, radian mỗi giây. Nhỏ hơn thì bẻ lái chậm và nhìn nặng nề.
const TURN_SPEED := 6.0

## Đứng nghỉ bao lâu giữa hai chuyến đi, giây. Bốc ngẫu nhiên trong khoảng này.
##
## Có quãng nghỉ mới ra dáng patience_left vật: đi liên tục không nghỉ nhìn như đồ chơi
## lên dây cót. Đây cũng là lúc animation `idle` được dùng tới.
const REST_MIN := 2.0
const REST_MAX := 5.0

## ► VÙNG ĐƯỢC PHÉP ĐI LẠI — hình chữ nhật trên mặt sàn, toạ độ (x, z).
##
## Doro KHÔNG được vào khu bếp. Hai lý do, lý do thứ hai mới là lý do thật:
##   1. Thú cưng lượn trong bếp thì chẳng còn là thú cưng của QUÁN nữa.
##   2. Nó chen vào giữa người chơi và các trạm. Bộ chọn mục tiêu quét một
##      hình hộp trước mặt và lấy trạm gần nhất — Doro đứng chắn thì bấm E ra
##      Doro chứ không ra cái bếp. Một thứ trang trí không bao giờ được phép
##      cướp thao tác.
##
## Vì sao phải khai vùng bằng tay chứ không để navmesh lo: navmesh CÓ phủ khu
## bếp. Hai tấm chắn vô hình chỉ ngắt ĐƯỜNG NỐI giữa bếp và khu khách, nên sàn
## bếp vẫn là một hòn đảo đi được nằm tách biệt. Doro sinh ra ở cạnh thùng rác
## — mà thùng rác nằm TRONG bếp — nên nó rơi đúng vào hòn đảo đó và không bao
## giờ ra được. Đây chính là lỗi user gặp.
##
## Bố cục map để tham khảo khi chỉnh: bản đồ 32 × 24; khu bếp nằm khoảng
## x 0…16, z 0…12; hàng đợi ở z = 2 (x 18…29); bàn ăn ở z = 12 và z = 19,
## x từ 6 tới 28. Vùng dưới đây là KHU KHÁCH ngồi ăn.
const AREA_MIN := Vector2(5.0, 14.0)    # góc (x nhỏ, z nhỏ)
const AREA_MAX := Vector2(30.0, 21.5)   # góc (x lớn, z lớn)

## Bán kính bốc điểm đến, tính từ CHỖ ĐANG ĐỨNG, mét.
##
## Bốc quanh chỗ đang đứng chứ không bốc trong cả bản đồ: bốc toàn bản đồ thì
## Doro băng từ đầu này sang đầu kia quán, mỗi chuyến mười giây, nhìn như đang
## có việc gấp. Quanh quẩn một vùng nhỏ mới ra dáng thú cưng.
const WANDER_RADIUS := 6.0

## Gần người chơi dưới bấy nhiêu mét thì ĐỨNG YÊN, mét.
##
## Để Doro dễ bấm trúng: bấm E cần patience_left trỏ nằm trên mục tiêu đúng lúc bấm, mà
## một mục tiêu đang bò ngang thì thành pha đuổi bắt. 2,2 nhỉnh hơn tầm với
## của bộ chọn mục tiêu một chút, nên lúc người chơi đủ gần để bấm thì Doro đã
## dừng từ trước.
##
## LƯU Ý khi tăng HEIGHT lên nhiều: Doro to thì nên tăng số này theo, không thì
## nó dừng lúc đã chồng lên người chơi rồi.
const NEAR_PLAYER := 2.2
