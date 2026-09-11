extends Control
func present(heading: String, instructions: String, primary: String, choices: Array, secondary: bool) -> void:
	for pair in [["Heading", heading], ["Instructions", instructions], ["PrimaryButton", primary]]:
		var node = get_node("Panel/Content/" + pair[0])
		if node.text != pair[1]: node.text = pair[1]
	$Panel/Content/PrimaryButton.visible = not primary.is_empty()
	$Panel/Content/PrimaryButton.disabled = primary.is_empty() or not visible
	$Panel/Content/SecondaryButton.visible = secondary
	$Panel/Content/SecondaryButton.disabled = not secondary or not visible
	for i in range(2):
		var button = get_node("Panel/Content/Choice%sButton" % ("A" if i == 0 else "B"))
		button.visible = choices.size() == 2
		button.disabled = not button.visible or not visible
		if button.visible:
			button.text = choices[i].text
			button.disabled = not choices[i].enabled

	# Restore fixed bounds after a previous modal with a larger minimum size.
	if $Panel.size != Vector2(350,326): $Panel.set_deferred("size", Vector2(350,326))

func present_journey(run: RunModel, time: float, paused: bool) -> void:
	for panel in [$Route, $Shrine, $Reveal]:
		panel.visible = visible and not paused and panel.name == ("Shrine" if run.state == RunModel.State.INTERMISSION else ("Reveal" if run.state == RunModel.State.CLEARED else "Route"))
		if panel.visible:
			# Route frames depict unlocked gates; only shrine/reveal animate.
			panel.present(run.journey_text(), mini(2, run.encounter_index / 3) * 0.3 if panel == $Route else time)
