extends RefCounted

## Các món BÁN ĐƯỢC có ham hoặc steak bên trong. Dùng cho CẢ hai việc: đếm
const MEAT_DISHES := [
	"mon_steak", "mon_ham", "dinner",
	"burger_plain", "burger_cheese", "burger_lettuce", "hambuger",
]


const ACTIVE := {
	"name": "Shooting Star",
	"condition": "orders_with_dishes",
	"dishes": MEAT_DISHES,
	"threshold": 5,
	"effect": "wildcard_dishes",
	"wildcard_dishes": MEAT_DISHES,
	"uses": 1,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Độc tày Spe-chan ──────────────────────────────────────────────
	"cook_time_cut": 4.0,
	"cook_time_cut_items": ["ham", "steak_uncook"],

	# ── Hốc phó ───────────────────────────────────────────────────────
	"bonus_payout_chance": 0.20,
	"bonus_payout_multiplier": 3.0,
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
const ASIAN := {
	"active": {"threshold": 8},
	"passive": {"cook_time_cut": 2.0, "bonus_payout_chance": 0.10},
}
