/*******************************************************************************
** @file       FocusFrame.cpp
** @author     Gunics Balázs
** @copyright  The Open-Agriculture Developers
*******************************************************************************/
#include "FocusFrame.hpp"

#include "isobus/isobus/isobus_virtual_terminal_objects.hpp"

void FocusFrame::paint(Graphics &g, Component &area, std::uint16_t objectID)
{
	if (isobus::NULL_OBJECT_ID != objectID)
	{
		paint_children(g, area, area, objectID);
	}
}

void FocusFrame::paint_children(Graphics &g, Component &area, Component &parent, std::uint16_t objectID)
{
	for (auto child : parent.getChildren())
	{
		if (!child->isVisible())
		{
			continue;
		}

		auto object = dynamic_cast<isobus::VTObject *>(child);

		if ((nullptr != object) && (objectID == object->get_id()))
		{
			// Around the object, so it stays readable, but kept inside the area
			const auto bounds = area.getLocalArea(child, child->getLocalBounds()).toFloat();
			const auto frame = bounds.expanded(FRAME_WIDTH).getIntersection(area.getLocalBounds().toFloat());
			g.setColour(area.findColour(TextEditor::focusedOutlineColourId));
			g.drawRect(frame, FRAME_WIDTH);
		}
		else
		{
			paint_children(g, area, *child, objectID);
		}
	}
}
