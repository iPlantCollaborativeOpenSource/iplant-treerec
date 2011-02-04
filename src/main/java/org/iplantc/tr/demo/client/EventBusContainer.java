package org.iplantc.tr.demo.client;

import org.iplantc.core.broadcaster.shared.BroadcastCommand;
import org.iplantc.tr.demo.client.commands.EventBusBroadcastCommand;
import org.iplantc.tr.demo.client.panels.ChannelContainer;

import com.google.gwt.event.shared.SimpleEventBus;

/**
 * Abstract class for implementing a channel container with a simple event bus.
 * 
 * @author amuir
 * 
 */
public abstract class EventBusContainer extends ChannelContainer
{
	protected SimpleEventBus eventbus;

	/**
	 * Default constructor.
	 */
	protected EventBusContainer()
	{
		eventbus = new SimpleEventBus();
	}

	/**
	 * Build a broadcast command.
	 * 
	 * @param id unique id for this command.
	 * @return newly create broadcast command.
	 */
	protected BroadcastCommand buildBroadcastCommand(final String id)
	{
		return (BroadcastCommand)new EventBusBroadcastCommand(id, eventbus);
	}
}
