package org.iplantc.tr.demo.client.receivers;

import org.iplantc.tr.demo.client.utils.JsonUtil;

import com.google.gwt.event.shared.EventBus;
import com.google.gwt.json.client.JSONObject;

public class SpeciesTreeSearchModeReceiver extends TreeReceiver
{

	public SpeciesTreeSearchModeReceiver(EventBus eventbus, String id)
	{
		super(eventbus, id);
		// TODO Auto-generated constructor stub
	}

	@Override
	protected void processChannelMessage(String idBroadcaster, String jsonMsg)
	{
		JSONObject objJson = JsonUtil.getObject(jsonMsg);

		if(objJson != null)
		{
			if(isOurEvent(idBroadcaster))
			{
				String event = JsonUtil.getString(objJson, "event");

				System.out.println("event-->" + event.toString());

				if(event.equals("branch_clicked"))
				{
					handleBranchClick(objJson);
				}

				if(event.equals("node_mouse_over") || event.equals("leaf_mouse_over") || event.equals("branch_mouse_over") || event.equals("label_mouse_over"))
				{
					handleNodeMouseOver(objJson);
				}

				if(event.equals("node_mouse_out") || event.equals("leaf_mouse_out") || event.equals("branch_mouse_out") || event.equals("label_mouse_out"))
				{
					handleNodeMouseOut(objJson);
				}
				
				
			}
		}

	}

	private void handleBranchClick(JSONObject objJson)
	{
		String event = JsonUtil.getString(objJson, "event");
		
		String id = JsonUtil.getString(objJson, "id");
		
		System.out.println("event received" + event + "->" + id);
		

		
	}

}
