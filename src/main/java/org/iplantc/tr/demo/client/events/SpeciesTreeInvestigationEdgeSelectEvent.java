package org.iplantc.tr.demo.client.events;

import com.extjs.gxt.ui.client.util.Point;

/**
 * {@inheritDoc}
 */
public class SpeciesTreeInvestigationEdgeSelectEvent extends TreeEdgeSelectedEvent<SpeciesTreeInvestigationEdgeSelectEventHandler>
{

	public static final Type<SpeciesTreeInvestigationEdgeSelectEventHandler> TYPE = new Type<SpeciesTreeInvestigationEdgeSelectEventHandler>();
 	
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
	@Override
	public Type<SpeciesTreeInvestigationEdgeSelectEventHandler> getAssociatedType()
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
