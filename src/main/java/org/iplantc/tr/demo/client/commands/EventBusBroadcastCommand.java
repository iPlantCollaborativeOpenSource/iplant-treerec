package org.iplantc.tr.demo.client.commands;

import org.iplantc.core.broadcaster.shared.BroadcastCommand;
import org.iplantc.tr.demo.client.events.ChannelEvent;

import com.google.gwt.event.shared.EventBus;

/**
 * Event bus implementation of a broadcast command.
 * 
 * @author amuir
 * 
 */
public class EventBusBroadcastCommand implements BroadcastCommand
{
	protected final String id;
	private EventBus eventbus;

	/**
	 * Instantiate from id and eventbus.
	 * 
	 * @param id unique id for this broadcaster.
	 * @param eventbus event bus for firing/receiving events.
	 */
	public EventBusBroadcastCommand(final String id, final EventBus eventbus)
	{
		this.id = id;
		this.eventbus = eventbus;
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	public void broadcast(String jsonMsg)
	{
		ChannelEvent event = new ChannelEvent(id, jsonMsg);

		eventbus.fireEvent(event);
	}
}
