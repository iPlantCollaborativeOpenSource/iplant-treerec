package org.iplantc.tr.demo.client.events;

import com.google.gwt.event.shared.GwtEvent;

public class HighlightSpeciesSubTreeEvent extends
		HighlightSubTreeEvent<HighlightSpeciesSubTreeEventHandler>
{

	public static final GwtEvent.Type<HighlightSpeciesSubTreeEventHandler> TYPE =
			new GwtEvent.Type<HighlightSpeciesSubTreeEventHandler>();

	public HighlightSpeciesSubTreeEvent(int idEdgeToNode)
	{
		super(idEdgeToNode);

	}

	@Override
	protected void dispatch(HighlightSpeciesSubTreeEventHandler handler)
	{
		handler.onFire(this);

	}

	@Override
	public com.google.gwt.event.shared.GwtEvent.Type<HighlightSpeciesSubTreeEventHandler> getAssociatedType()
	{
		return TYPE;
	}

}
