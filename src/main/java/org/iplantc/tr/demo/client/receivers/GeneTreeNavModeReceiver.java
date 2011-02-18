package org.iplantc.tr.demo.client.receivers;

import org.iplantc.tr.demo.client.events.GeneTreeNavNodeSelectEvent;
import org.iplantc.tr.demo.client.utils.JsonUtil;

import com.google.gwt.event.shared.EventBus;
import com.google.gwt.json.client.JSONObject;

/**
 * Receiver used for the gene tree when it is in navigation mode.
 * 
 * @author amuir
 * 
 */
public class GeneTreeNavModeReceiver extends TreeReceiver
{
	/**
	 * Instantiate from an event bus and id.
	 * 
	 * @param eventbus event bus for firing/receiving events.
	 * @param id unique id for this receiver.
	 */
	public GeneTreeNavModeReceiver(EventBus eventbus, String id)
	{
		super(eventbus, id);
	}

	private void handleNodeClick(final JSONObject objJson)
	{
		String id = JsonUtil.getString(objJson, "id");
		GeneTreeNavNodeSelectEvent event =
				new GeneTreeNavNodeSelectEvent(Integer.parseInt(id), getAbsoluteCoordinates(objJson));
		eventbus.fireEvent(event);
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
				if(event.equals("node_mouse_over") || event.equals("leaf_mouse_over")
						|| event.equals("branch_mouse_over") || event.equals("label_mouse_over"))
				{
					handleNodeMouseOver(objJson);
				}

				if(event.equals("node_mouse_out") || event.equals("leaf_mouse_out")
						|| event.equals("branch_mouse_out") || event.equals("label_mouse_out"))
				{
					handleNodeMouseOut(objJson);
				}
			}
		}
	}
}
