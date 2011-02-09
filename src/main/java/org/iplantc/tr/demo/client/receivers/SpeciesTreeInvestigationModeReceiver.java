package org.iplantc.tr.demo.client.receivers;

import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationEdgeSelectEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationNodeSelectEvent;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOutEvent;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOverEvent;
import org.iplantc.tr.demo.client.utils.JsonUtil;

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
		SpeciesTreeInvestigationNodeSelectEvent event = new SpeciesTreeInvestigationNodeSelectEvent(
				Integer.parseInt(id),getAbsoluteCoordinates(objJson));
		eventbus.fireEvent(event);
	}
	
	private void handleEdgeClick(final JSONObject objJson)
	{
		String id = JsonUtil.getString(objJson, "id");
	
		
		SpeciesTreeInvestigationEdgeSelectEvent event = new SpeciesTreeInvestigationEdgeSelectEvent(Integer
				.parseInt(id), getAbsoluteCoordinates(objJson));
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
				
				System.out.println("event-->" + event.toString());

				if(event.equals("node_clicked"))
				{
					handleNodeClick(objJson);
				}
				
				if (event.equals("branch_clicked"))
				{
					handleEdgeClick(objJson);
				}
				
				if (event.equals("node_mouse_over") || event.equals("leaf_mouse_over"))
				{
					handleNodeMouseOver(objJson);
				}
				
				if (event.equals("node_mouse_out") || event.equals("leaf_mouse_out"))
				{
					handleNodeMouseOut(objJson);
				}
				
				if (event.equals("leaf_clicked"))
				{
					handleLeafClick(objJson);
				}
			}
		}
	}
	
	
	private void handleLeafClick(JSONObject objJson)
	{
		String id = JsonUtil.getString(objJson, "id");
		//TODO: make service call to retrieve genes for this species and fire event
		
		
	}

	private void handleNodeMouseOut(JSONObject objJson)
	{
		String id = JsonUtil.getString(objJson, "id");
		TreeNodeMouseOutEvent event = new TreeNodeMouseOutEvent(Integer.parseInt(id), getAbsoluteCoordinates(objJson));
		eventbus.fireEvent(event);
	}

	private void handleNodeMouseOver(JSONObject objJson)
	{
		String id = JsonUtil.getString(objJson, "id");
		TreeNodeMouseOverEvent event = new TreeNodeMouseOverEvent(Integer.parseInt(id), getAbsoluteCoordinates(objJson));
		eventbus.fireEvent(event);
	}

}
