package org.iplantc.tr.demo.client.events;

import java.util.ArrayList;

import com.google.gwt.event.shared.GwtEvent;

public class HighlightNodesInGeneTreeEvent extends
		GwtEvent<HighlightNodesInGeneTreeEventHandler>
{

	private ArrayList<Integer> nodesToHighlight;

	/**
	 * @return the nodesToHighlight
	 */
	public ArrayList<Integer> getNodesToHighlight()
	{
		return nodesToHighlight;
	}

	public HighlightNodesInGeneTreeEvent(ArrayList<Integer> nodesToHighlight)
	{
		this.nodesToHighlight = nodesToHighlight;
	}

	public static final GwtEvent.Type<HighlightNodesInGeneTreeEventHandler> TYPE =
			new GwtEvent.Type<HighlightNodesInGeneTreeEventHandler>();

	@Override
	public Type<HighlightNodesInGeneTreeEventHandler> getAssociatedType()
	{
		return TYPE;
	}

	@Override
	protected void dispatch(HighlightNodesInGeneTreeEventHandler handler)
	{
		handler.onFire(this);
	}

}
