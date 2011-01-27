package org.iplantc.tr.demo.client.receivers;

import org.iplantc.tr.demo.client.events.ChannelEvent;
import org.iplantc.tr.demo.client.events.ChannelEventHandler;

import com.google.gwt.event.shared.EventBus;

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

	/**
	 * Processes messages from channel events.
	 * 
	 * @param idBroadcaster unique id of broadcaster which fired this event.
	 * @param jsonMsg event message in JSON.
	 */
	protected abstract void processChannelMessage(final String idBroadcaster, final String jsonMsg);
}
