package org.iplantc.tr.demo.client.events;

import com.google.gwt.event.shared.GwtEvent;

public class HighlightGeneSubTreeEvent extends HighlightSubTreeEvent<HighlightGeneSubTreeEventHandler>
{

	public static final GwtEvent.Type<HighlightGeneSubTreeEventHandler> TYPE =
			new GwtEvent.Type<HighlightGeneSubTreeEventHandler>();

	public HighlightGeneSubTreeEvent(int idNode)
	{
		super(idNode);

	}

	@Override
	protected void dispatch(HighlightGeneSubTreeEventHandler handler)
	{
		handler.onFire(this);

	}

	@Override
	public com.google.gwt.event.shared.GwtEvent.Type<HighlightGeneSubTreeEventHandler> getAssociatedType()
	{
		return TYPE;
	}

}
