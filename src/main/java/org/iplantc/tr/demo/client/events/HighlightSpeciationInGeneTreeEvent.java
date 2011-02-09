package org.iplantc.tr.demo.client.events;

import java.util.ArrayList;

import com.google.gwt.event.shared.GwtEvent;

public class HighlightSpeciationInGeneTreeEvent extends
		GwtEvent<HighlightSpeciationInGeneTreeEventHandler>
{

	private ArrayList<Integer> nodesToHighlight;

	/**
	 * @return the nodesToHighlight
	 */
	public ArrayList<Integer> getNodesToHighlight()
	{
		return nodesToHighlight;
	}

	public HighlightSpeciationInGeneTreeEvent(ArrayList<Integer> nodesToHighlight)
	{
		this.nodesToHighlight = nodesToHighlight;
	}

	public static final GwtEvent.Type<HighlightSpeciationInGeneTreeEventHandler> TYPE =
			new GwtEvent.Type<HighlightSpeciationInGeneTreeEventHandler>();

	@Override
	public Type<HighlightSpeciationInGeneTreeEventHandler> getAssociatedType()
	{
		return TYPE;
	}

	@Override
	protected void dispatch(HighlightSpeciationInGeneTreeEventHandler handler)
	{
		handler.onFire(this);
	}

}
