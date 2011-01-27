package org.iplantc.tr.demo.client.events;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.GwtEvent;

/**
 * Event fired on species tree investigation mode node selection.
 * 
 * @author amuir
 * 
 */
public class SpeciesTreeInvestigationNodeSelectEvent extends
		TreeNodeSelectEvent<SpeciesTreeInvestigationNodeSelectEventHandler>
{
	public static final GwtEvent.Type<SpeciesTreeInvestigationNodeSelectEventHandler> TYPE = new GwtEvent.Type<SpeciesTreeInvestigationNodeSelectEventHandler>();

	/**
	 * Instantiate from a node id.
	 * 
	 * @param idNode unique id associated with the selected node.
	 * @param point x,y coordinate in which user clicked
	 */
	public SpeciesTreeInvestigationNodeSelectEvent(int idNode, Point p)
	{
		super(idNode, p);
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void dispatch(SpeciesTreeInvestigationNodeSelectEventHandler handler)
	{
		handler.onFire(this);
	}

	@Override
	public com.google.gwt.event.shared.GwtEvent.Type<SpeciesTreeInvestigationNodeSelectEventHandler> getAssociatedType()
	{
		return TYPE;
	}
}
