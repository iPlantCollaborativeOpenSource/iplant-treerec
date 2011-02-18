package org.iplantc.tr.demo.client.events;

import java.util.ArrayList;

import com.google.gwt.event.shared.GwtEvent;

public class HighlightBranchesInSpeciesTreeEvent extends
		GwtEvent<HighlightBranchesInSpeciesTreeEventHandler>
{

	private ArrayList<Integer> nodesToHighlight;

	/**
	 * @return the nodesToHighlight
	 */
	public ArrayList<Integer> getNodesToHighlight()
	{
		return nodesToHighlight;
	}

	public HighlightBranchesInSpeciesTreeEvent(ArrayList<Integer> nodesToHighlight)
	{
		this.nodesToHighlight = nodesToHighlight;
	}

	public static final GwtEvent.Type<HighlightBranchesInSpeciesTreeEventHandler> TYPE =
			new GwtEvent.Type<HighlightBranchesInSpeciesTreeEventHandler>();

	@Override
	public Type<HighlightBranchesInSpeciesTreeEventHandler> getAssociatedType()
	{
		return TYPE;
	}

	@Override
	protected void dispatch(HighlightBranchesInSpeciesTreeEventHandler handler)
	{
		handler.onFire(this);
	}

}
