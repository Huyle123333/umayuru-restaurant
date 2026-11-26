extends RefCounted

const ICECREAMS := ["icecream_vani", "icecream_chocolate", "icecream_strawberry",
	"kem_tam_hop", "kem_tam_hop_que"]


const ACTIVE := {
	"name": "Sky-High Teio Step",
	"condition": "money_earned",
	"threshold": 1500,
	"script": "res://scripts/skills/effects/time_bonus.gd",
	"uses": 1,

	"bonus_seconds": 10.0,
}


const SECONDARY := {
	"name": "Fan tê liệt",
	"script": "res://scripts/skills/dish_picker.gd",
	"uses": 6,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Tưởng tày nhưng không ─────────────────────────────────────────
	"dish_price_factors": {
		"icecream_vani": 1.6,
		"icecream_chocolate": 1.6,
		"icecream_strawberry": 1.6,
		"kem_tam_hop": 1.6,
		"kem_tam_hop_que": 1.6,
	},
	"dish_weight_factors": {
		"icecream_vani": 0.5,
		"icecream_chocolate": 0.5,
		"icecream_strawberry": 0.5,
		"kem_tam_hop": 0.5,
		"kem_tam_hop_que": 0.5,
	},
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
const ASIAN := {
	"active": {
		"script": "res://scripts/skills/effects/patience_bonus.gd",
		"bonus_patience": 5.0,
	},
	"secondary": {"uses": 2},
	"passive": {
		"dish_price_factors": {
			"icecream_vani": 1.3, "icecream_chocolate": 1.3, "icecream_strawberry": 1.3,
			"kem_tam_hop": 1.3, "kem_tam_hop_que": 1.3,
		},
	},
}
