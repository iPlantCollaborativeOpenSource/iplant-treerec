package org.iplantc.tr.demo.client.receivers;

import org.iplantc.tr.demo.client.events.TreeNodeMouseOutEvent;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOverEvent;
import org.iplantc.tr.demo.client.utils.JsonUtil;

import com.google.gwt.event.shared.EventBus;
import com.google.gwt.json.client.JSONObject;

public abstract class TreeReceiver extends EventBusReceiver
{

	public TreeReceiver(EventBus eventbus, String id)
	{
		super(eventbus, id);

	}

	protected void handleNodeMouseOut(JSONObject objJson)
	{
		String id = JsonUtil.getString(objJson, "id");
		TreeNodeMouseOutEvent event =
				new TreeNodeMouseOutEvent(Integer.parseInt(id), getAbsoluteCoordinates(objJson));
		eventbus.fireEvent(event);
	}

	protected void handleNodeMouseOver(JSONObject objJson)
	{
		String id = JsonUtil.getString(objJson, "id");
		TreeNodeMouseOverEvent event =
				new TreeNodeMouseOverEvent(Integer.parseInt(id), getAbsoluteCoordinates(objJson));
		eventbus.fireEvent(event);
	}

}
