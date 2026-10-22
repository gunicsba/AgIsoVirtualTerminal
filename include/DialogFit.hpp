/*******************************************************************************
** @file       DialogFit.hpp
** @copyright  The Open-Agriculture Developers
*******************************************************************************/
#ifndef DIALOG_FIT_HPP
#define DIALOG_FIT_HPP

#include "JuceHeader.h"

/// The VT's dialogs cannot scroll, and a phone is shorter than some of them. On Android a dialog is
/// therefore shown inside host, centred and scaled down until it fits. Elsewhere it stays a window of
/// its own and nothing changes.
inline void show_dialog_inside(juce::Component &dialog, juce::Component &host)
{
#if JUCE_ANDROID
	host.addAndMakeVisible(dialog);
	dialog.setTransform({});

	if ((dialog.getWidth() <= 0) || (dialog.getHeight() <= 0))
	{
		return;
	}
	dialog.centreWithSize(dialog.getWidth(), dialog.getHeight());

	const auto area = host.getLocalBounds().reduced(8);
	const float scale = juce::jmin(1.0f,
	                               static_cast<float>(area.getWidth()) / static_cast<float>(dialog.getWidth()),
	                               static_cast<float>(area.getHeight()) / static_cast<float>(dialog.getHeight()));
	const auto centre = dialog.getBounds().getCentre().toFloat();
	dialog.setTransform(juce::AffineTransform::scale(scale, scale, centre.x, centre.y));
#else
	juce::ignoreUnused(dialog, host);
#endif
}

#endif // DIALOG_FIT_HPP
