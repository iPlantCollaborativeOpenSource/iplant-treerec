package org.iplantc.tr.demo.client.receivers;

import org.iplantc.tr.demo.client.events.ChannelEvent;
import org.iplantc.tr.demo.client.events.ChannelEventHandler;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.EventBus;
import com.google.gwt.json.client.JSONObject;

/**
 * Abstract class for implementing a receiver with an event bus.
 * 
 * @author amuir
 * 
 */
public abstract class EventBusReceiver extends Receiver
{
	protected final EventBus eventbus;
	protected final String id;

	/**
	 * Instantiate from an event bus and id.
	 * 
	 * @param eventbus event bus for firing/receiving events.
	 * @param id unique id for this receiver.
	 */
	public EventBusReceiver(final EventBus eventbus, final String id)
	{
		this.eventbus = eventbus;
		this.id = id;

		initListeners();
	}

	/**
	 * Initialize event listening.
	 */
	protected void initListeners()
	{
		if(eventbus != null)
		{
			eventbus.addHandler(ChannelEvent.TYPE, new ChannelEventHandler()
			{
				@Override
				public void onFire(ChannelEvent event)
				{
					if(isEnabled())
					{
						processChannelMessage(event.getBroadcasterId(), event.getMessage());
					}
				}
			});
		}
	}
	
	protected Point getAbsoluteCoordinates(JSONObject obj)
	{
		Point ret = null;   //assume failure
		
		if(obj != null)
		{		
			String temp = obj.get("clicked_x").toString();
			int x = Integer.parseInt(temp);
	
			temp =  obj.get("clicked_y").toString();
			int y = Integer.parseInt(temp);
	
			ret = new Point(x,y);
		}
		
		return ret;
	}

	/**
	 * Processes messages from channel events.
	 * 
	 * @param idBroadcaster unique id of broadcaster which fired this event.
	 * @param jsonMsg event message in JSON.
	 */
	protected abstract void processChannelMessage(final String idBroadcaster, final String jsonMsg);	
}
