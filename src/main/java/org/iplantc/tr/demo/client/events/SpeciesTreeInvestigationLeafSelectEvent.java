package org.iplantc.tr.demo.client.events;

import com.google.gwt.event.shared.GwtEvent;

public class SpeciesTreeInvestigationLeafSelectEvent extends
		GwtEvent<SpeciesTreeInvestigationLeafSelectEventHandler>
{

	public static final GwtEvent.Type<SpeciesTreeInvestigationLeafSelectEventHandler> TYPE =
			new GwtEvent.Type<SpeciesTreeInvestigationLeafSelectEventHandler>();

	private int idNode;
	
	
	public SpeciesTreeInvestigationLeafSelectEvent(int nodeId)
	{
		idNode = nodeId;
	}

	/**
	 * @return the idNode
	 */
	public int getIdNode()
	{
		return idNode;
	}

	/**
	 * @return the geneTreeNodesToSelect
	 */
	@Override
	protected void dispatch(SpeciesTreeInvestigationLeafSelectEventHandler handler)
	{
		handler.onFire(this);

	}

	@Override
	public com.google.gwt.event.shared.GwtEvent.Type<SpeciesTreeInvestigationLeafSelectEventHandler> getAssociatedType()
	{
		return TYPE;
	}

}
