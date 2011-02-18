package org.iplantc.tr.demo.client.events;

import java.util.ArrayList;

import com.google.gwt.event.shared.GwtEvent;

public class HighlightNodesInSpeciesTreeEvent extends GwtEvent<HighlightNodesInSpeciesTreeEventHandler>
{

	private ArrayList<Integer> nodesToHighlight;

	/**
	 * @return the nodesToHighlight
	 */
	public ArrayList<Integer> getNodesToHighlight()
	{
		return nodesToHighlight;
	}

	public HighlightNodesInSpeciesTreeEvent(ArrayList<Integer> nodesToHighlight)
	{
		this.nodesToHighlight = nodesToHighlight;
	}

	public static final GwtEvent.Type<HighlightNodesInSpeciesTreeEventHandler> TYPE =
			new GwtEvent.Type<HighlightNodesInSpeciesTreeEventHandler>();

	@Override
	public Type<HighlightNodesInSpeciesTreeEventHandler> getAssociatedType()
	{
		return TYPE;
	}

	@Override
	protected void dispatch(HighlightNodesInSpeciesTreeEventHandler handler)
	{
		handler.onFire(this);
	}

}
