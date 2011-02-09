package org.iplantc.tr.demo.client.events;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.GwtEvent;

/**
 * Event fired on species tree navigation mode node selection.
 * 
 * @author amuir
 * 
 */
public class SpeciesTreeNavNodeSelectEvent extends
		TreeNodeSelectEvent<SpeciesTreeNavNodeSelectEventHandler>
{
	public static final GwtEvent.Type<SpeciesTreeNavNodeSelectEventHandler> TYPE =
			new GwtEvent.Type<SpeciesTreeNavNodeSelectEventHandler>();

	/**
	 * Instantiate from a node id.
	 * 
	 * @param idNode unique id associated with the selected node.
	 */
	public SpeciesTreeNavNodeSelectEvent(int idNode, Point p)
	{
		super(idNode, p);
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void dispatch(SpeciesTreeNavNodeSelectEventHandler handler)
	{
		handler.onFire(this);
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	public com.google.gwt.event.shared.GwtEvent.Type<SpeciesTreeNavNodeSelectEventHandler> getAssociatedType()
	{
		return TYPE;
	}
}
