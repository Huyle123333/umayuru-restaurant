extends RefCounted

const PIZZAS := ["pizza_cheese", "pizza_mushroom", "pizza_peperoni"]


const ACTIVE := {
	"name": "Go, Go, Mun!",
	"condition": "orders_done",
	"threshold": 15,
	"script": "res://scripts/skills/effects/go_go_mun.gd",
	"uses": 1,

	"perfect_roll": {
		"dishes": PIZZAS,
		"rolls": [[0.36, 3.0], [0.18, 2.0]],
	},
	"stun_chance_per_second": 0.03,
	"stun_seconds": 2.0,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Mambo tongye ──────────────────────────────────────────────────
	"cook_time_cut": 4.0,
	"cook_time_cut_items": ["*"],
	"bake_time_cut": 4.0,

	# ── Vua làm nền ───────────────────────────────────────────────────
	"dish_weight_factors": {
		"pizza_cheese": 1.2,
		"pizza_mushroom": 1.2,
		"pizza_peperoni": 1.2,
	},
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
const ASIAN := {
	"active": {"threshold": 20},
	"passive": {"cook_time_cut": 2.0, "bake_time_cut": 2.0},
}
