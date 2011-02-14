package org.iplantc.tr.demo.client.panels;

import org.iplantc.tr.demo.client.utils.PanelHelper;

import com.extjs.gxt.ui.client.event.ButtonEvent;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.widget.button.Button;
import com.extjs.gxt.ui.client.widget.toolbar.FillToolItem;
import com.extjs.gxt.ui.client.widget.toolbar.ToolBar;
import com.google.gwt.event.shared.EventBus;

/**
 * Navigation tree panel (contains 'Home' and 'Clear Highlights' buttons)
 * 
 * @author amuir
 * 
 */
public class NavTreeChannelPanel extends TreeChannelPanel
{
	/**
	 * Instantiate from an event bus, caption, id, tree and layout
	 * 
	 * @param eventbus event bus for firing/receiving events.
	 * @param caption text to display in panel heading.
	 * @param id unique id for this panel.
	 * @param jsonTree tree data.
	 * @param layoutTree layout data.
	 */
	public NavTreeChannelPanel(EventBus eventbus, String caption, String id, String jsonTree,
			String layoutTree)
	{
		super(eventbus, caption, id, jsonTree, layoutTree);
	}

	private Button buildHomeButton()
	{
		return PanelHelper.buildButton("idHomeBtn", "Home", new SelectionListener<ButtonEvent>()
		{
			@Override
			public void componentSelected(ButtonEvent ce)
			{
				if(treeView != null)
				{
					treeView.zoomToFit();
				}
			}
		});
	}

	private Button buildClearHighlightsButton()
	{
		return PanelHelper.buildButton("idClearHighlightsBtn", "Clear Highlights",
				new SelectionListener<ButtonEvent>()
				{
					@Override
					public void componentSelected(ButtonEvent ce)
					{
						if(treeView != null)
						{
							treeView.clearHighlights();
							treeView.requestRender();
						}
					}
				});
	}

	private ToolBar buildToolbar()
	{
		ToolBar ret = new ToolBar();

		ret.add(new FillToolItem());

		ret.add(buildClearHighlightsButton());
		ret.add(buildHomeButton());

		return ret;
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void compose()
	{
		setTopComponent(buildToolbar());

		super.compose();
	}
}
