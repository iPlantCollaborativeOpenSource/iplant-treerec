package org.iplantc.tr.demo.client.events;

import java.util.ArrayList;

import com.google.gwt.event.shared.GwtEvent;

public class SpeciesTreeInvestigationLeafSelectEvent extends
		GwtEvent<SpeciesTreeInvestigationLeafSelectEventHandler>
{

	public static final GwtEvent.Type<SpeciesTreeInvestigationLeafSelectEventHandler> TYPE =
			new GwtEvent.Type<SpeciesTreeInvestigationLeafSelectEventHandler>();

	private ArrayList<Integer> geneTreeNodesToSelect;

	/**
	 * @return the geneTreeNodesToSelect
	 */
	public ArrayList<Integer> getGeneTreeNodesToSelect()
	{
		return geneTreeNodesToSelect;
	}

	public SpeciesTreeInvestigationLeafSelectEvent(ArrayList<Integer> geneTreeNodesToSelect)
	{
		this.geneTreeNodesToSelect = geneTreeNodesToSelect;
	}

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
