extends RefCounted
## ─────────────────────────────────────────────────── CÁCH CHỈNH


## ► CHIỀU HEIGHT CỦA DORO TRONG GAME, tính bằng MÉT. Đây là con số bạn muốn sửa.
const HEIGHT := 0.9

## Chiều cao MODEL GỐC, đo trong Blender (hộp bao thế giới, trục Z = 2,115).
const BASE_HEIGHT := 2.115

## Cạnh hộp va chạm theo chiều ngang, tính theo phần trăm chiều cao.
const BOX_WIDTH := 1.15


## Tốc độ đi, mét mỗi giây. Nhân vật người chơi đi 6,4 — Doro chậm hơn nhiều
const SPEED := 1.4

## Tốc độ xoay người, radian mỗi giây. Nhỏ hơn thì bẻ lái chậm và nhìn nặng nề.
const TURN_SPEED := 6.0

## Đứng nghỉ bao lâu giữa hai chuyến đi, giây. Bốc ngẫu nhiên trong khoảng này.
const REST_MIN := 2.0
const REST_MAX := 5.0

## ► VÙNG ĐƯỢC PHÉP ĐI LẠI — hình chữ nhật trên mặt sàn, toạ độ (x, z).
const AREA_MIN := Vector2(5.0, 14.0)
const AREA_MAX := Vector2(30.0, 21.5)

## Bán kính bốc điểm đến, tính từ CHỖ ĐANG ĐỨNG, mét.
const WANDER_RADIUS := 6.0

## Gần người chơi dưới bấy nhiêu mét thì ĐỨNG YÊN, mét.
const NEAR_PLAYER := 2.2
