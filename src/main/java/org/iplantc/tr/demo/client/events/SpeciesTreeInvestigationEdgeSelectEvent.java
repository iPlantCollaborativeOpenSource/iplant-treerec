package org.iplantc.tr.demo.client.events;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.GwtEvent;

/**
 * {@inheritDoc}
 */
public class SpeciesTreeInvestigationEdgeSelectEvent extends TreeEdgeSelectedEvent<SpeciesTreeInvestigationEdgeSelectEventHandler>
{

	public static final GwtEvent.Type<SpeciesTreeInvestigationEdgeSelectEventHandler> TYPE = new Type<SpeciesTreeInvestigationEdgeSelectEventHandler>();
 	
	/**
	 * Instantiate from a node id.
	 * 
	 * @param idNode unique id associated with the edge leading to node.
	 * @param point x,y coordinate in which user clicked
	 */
	public SpeciesTreeInvestigationEdgeSelectEvent(int id, Point p)
	{
		super(id,p);
		
	}

	/**
	 * {@inheritDoc}
	 */
	@SuppressWarnings("unchecked")
	@Override
	public Type getAssociatedType()
	{
		return TYPE;
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void dispatch(SpeciesTreeInvestigationEdgeSelectEventHandler handler)
	{
		handler.onFire(this);
		
	}

}
