package org.iplantc.tr.demo.client.events;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.GwtEvent;

/**
 * Event fired on gene tree investigation mode node selection.
 * 
 * @author amuir
 * 
 */
public class GeneTreeInvestigationNodeSelectEvent extends
		TreeNodeSelectEvent<GeneTreeInvestigationNodeSelectEventHandler>
{
	public static final GwtEvent.Type<GeneTreeInvestigationNodeSelectEventHandler> TYPE =
			new GwtEvent.Type<GeneTreeInvestigationNodeSelectEventHandler>();

	/**
	 * Instantiate from a node id.
	 * 
	 * @param idNode unique id associated with the selected node.
	 * @param point x,y coordinate in which user clicked
	 */
	public GeneTreeInvestigationNodeSelectEvent(int idNode, Point p)
	{
		super(idNode, p);
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void dispatch(GeneTreeInvestigationNodeSelectEventHandler handler)
	{
		handler.onFire(this);
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	public com.google.gwt.event.shared.GwtEvent.Type<GeneTreeInvestigationNodeSelectEventHandler> getAssociatedType()
	{
		// TODO Auto-generated method stub
		return TYPE;
	}
}
