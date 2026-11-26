extends RefCounted


const ACTIVE := {
	"name": "Triumphant Pulse",
	"condition": "time_elapsed",
	"threshold": 240,
	"toggle": true,
	"budget_seconds": 30.0,
	"script": "res://scripts/skills/effects/time_stop.gd",
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Alo vũ à vũ ───────────────────────────────────────────────────
	"dish_price_factors": {
		"pizza_cheese": 1.6,
		"pizza_mushroom": 1.6,
		"pizza_peperoni": 1.6,
	},

	# ── Hốc trưởng ────────────────────────────────────────────────────
	"refill_stamina_on_order": true,
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
const ASIAN := {
	"active": {"threshold": 360, "budget_seconds": 15.0},
	"passive": {
		"dish_price_factors": {"pizza_cheese": 1.3, "pizza_mushroom": 1.3, "pizza_peperoni": 1.3},
	},
}
