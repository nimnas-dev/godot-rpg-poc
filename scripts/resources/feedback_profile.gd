class_name FeedbackProfile
extends Resource

@export_range(0.0, 12.0, 0.5) var max_camera_shake := 6.0
@export_range(1, 128, 1) var high_quality_effect_limit := 48
@export_range(1, 128, 1) var low_quality_effect_limit := 24
@export_range(1, 24, 1) var max_impact_voices := 8
@export_range(0.02, 1.0, 0.01) var reduced_motion_effect_duration := 0.12
