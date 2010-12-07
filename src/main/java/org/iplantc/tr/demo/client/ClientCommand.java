package org.iplantc.tr.demo.client;

/**
 * Basic interface for command pattern.
 * 
 * @author amuir
 * 
 */
public interface ClientCommand
{
	/**
	 * Execute command.
	 */
	void execute(final String params);
}
