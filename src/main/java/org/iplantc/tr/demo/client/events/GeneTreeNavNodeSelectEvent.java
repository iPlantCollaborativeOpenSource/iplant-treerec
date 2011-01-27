package org.iplantc.tr.demo.client.events;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.GwtEvent;

/**
 * Event fired on gene tree navigation mode node selection.
 * 
 * @author amuir
 * 
 */
public class GeneTreeNavNodeSelectEvent extends TreeNodeSelectEvent<GeneTreeNavNodeSelectEventHandler>
{
	public static final GwtEvent.Type<GeneTreeNavNodeSelectEventHandler> TYPE = new GwtEvent.Type<GeneTreeNavNodeSelectEventHandler>();

	/**
	 * Instantiate from a node id.
	 * 
	 * @param idNode unique id associated with the selected node.
	 * @param point x,y coordinate in which user clicked
	 */
	public GeneTreeNavNodeSelectEvent(int idNode, Point p)
	{
		super(idNode, p);
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void dispatch(GeneTreeNavNodeSelectEventHandler handler)
	{
		handler.onFire(this);
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	public com.google.gwt.event.shared.GwtEvent.Type<GeneTreeNavNodeSelectEventHandler> getAssociatedType()
	{
		return TYPE;
	}
}
