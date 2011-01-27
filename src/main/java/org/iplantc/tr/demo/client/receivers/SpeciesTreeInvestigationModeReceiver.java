package org.iplantc.tr.demo.client.receivers;

import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationEdgeSelectEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationNodeSelectEvent;
import org.iplantc.tr.demo.client.utils.JsonUtil;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.EventBus;
import com.google.gwt.json.client.JSONObject;

/**
 * Receiver used for the species tree when it is in investigation mode.
 * 
 * @author amuir
 * 
 */
public class SpeciesTreeInvestigationModeReceiver extends EventBusReceiver
{
	/**
	 * Instantiate from an event bus and id.
	 * 
	 * @param eventbus event bus for firing/receiving events.
	 * @param id unique id for this receiver.
	 */
	public SpeciesTreeInvestigationModeReceiver(EventBus eventbus, String id)
	{
		super(eventbus, id);
	}

	private void handleNodeClick(final JSONObject objJson)
	{
		String id = JsonUtil.getString(objJson, "id");
		int x = (int) objJson.get("clicked_x").isNumber().doubleValue();
		int y = (int) objJson.get("clicked_y").isNumber().doubleValue();
		Point p = new Point(x,y);
		SpeciesTreeInvestigationNodeSelectEvent event = new SpeciesTreeInvestigationNodeSelectEvent(
				Integer.parseInt(id),p);
		eventbus.fireEvent(event);
	}
	
	private void handleEdgeClick(final JSONObject objJson)
	{
		String id = JsonUtil.getString(objJson, "id");
		int x = (int) objJson.get("clicked_x").isNumber().doubleValue();
		int y = (int) objJson.get("clicked_y").isNumber().doubleValue();
		Point p = new Point(x,y);
		
		SpeciesTreeInvestigationEdgeSelectEvent event = new SpeciesTreeInvestigationEdgeSelectEvent(Integer
				.parseInt(id), p);
		eventbus.fireEvent(event);
	}


	private boolean isOurEvent(final String idBroadcaster)
	{
		return id.equals(idBroadcaster);
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void processChannelMessage(final String idBroadcaster, String jsonMsg)
	{
		JSONObject objJson = JsonUtil.getObject(jsonMsg);

		if(objJson != null)
		{
			if(isOurEvent(idBroadcaster))
			{
				String event = JsonUtil.getString(objJson, "event");

				if(event.equals("node_clicked"))
				{
					handleNodeClick(objJson);
				}
				
				if (event.equals("branch_clicked"))
				{
					handleEdgeClick(objJson);
				}
			}
		}
	}

}
