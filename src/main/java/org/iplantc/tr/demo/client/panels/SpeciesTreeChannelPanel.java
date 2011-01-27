package org.iplantc.tr.demo.client.panels;

import com.extjs.gxt.ui.client.event.MenuEvent;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.util.Point;
import com.extjs.gxt.ui.client.widget.menu.Menu;
import com.extjs.gxt.ui.client.widget.menu.MenuItem;
import com.google.gwt.event.shared.EventBus;
import com.google.gwt.user.client.Random;
import com.google.gwt.user.client.Window;

/**
 * Channel panel that contains a species tree.
 * 
 * @author amuir
 * 
 */
public class SpeciesTreeChannelPanel extends TreeChannelPanel
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
	public SpeciesTreeChannelPanel(EventBus eventbus, String caption, String id, String jsonTree,
			String layoutTree)
	{
		super(eventbus, caption, id, jsonTree, layoutTree);
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleGeneTreeInvestigationNodeSelect(int idNode, Point p)
	{
		int cntNodes = treeView.getTree().getNumberOfNodes();

		treeView.clearHighlights();

		int id = 1 + Random.nextInt(cntNodes - 2);

		treeView.highlight(id);
		treeView.zoomToFitSubtree(id);
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleGeneTreeNavNodeSelect(int idNode, Point p)
	{
		int cntNodes = treeView.getTree().getNumberOfNodes();

		int id = 1 + Random.nextInt(cntNodes - 2);

		treeView.zoomToFitSubtree(id);
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleSpeciesTreeInvestigationNodeSelect(int idNode, Point p)
	{
		// treeView.clearHighlights();
		// treeView.highlight(idNode);
		//
		// treeView.requestRender();

		displayMenu(p);
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleSpeciesTreeNavNodeSelect(int idNode, Point p)
	{
		treeView.zoomToFitSubtree(idNode);
	}

	private void displayMenu(Point p)
	{
		Menu m = new Menu();
		m.add(buildHighlightSpeciesMenuItem());
		m.add(buildHighlightAllMenuItem());
		m.add(buildSelectSubTreeMenuItem());
		m.showAt(p.x, p.y);
	}

	private MenuItem buildSelectSubTreeMenuItem()
	{
		MenuItem m = new MenuItem("Highlight speciation event in gene tree");
		m.addSelectionListener(new SelectionListener<MenuEvent>()
		{

			@Override
			public void componentSelected(MenuEvent ce)
			{
				// TODO Auto-generated method stub

			}
		});

		return m;
	}

	private MenuItem buildHighlightAllMenuItem()
	{
		MenuItem m = new MenuItem("Highlight all descendants");
		m.addSelectionListener(new SelectionListener<MenuEvent>()
		{

			@Override
			public void componentSelected(MenuEvent ce)
			{
				// TODO Auto-generated method stub

			}
		});

		return m;
	}

	private MenuItem buildHighlightSpeciesMenuItem()
	{
		MenuItem m = new MenuItem("Select sub tree (hide non selected species)");
		m.addSelectionListener(new SelectionListener<MenuEvent>()
		{

			@Override
			public void componentSelected(MenuEvent ce)
			{
				// TODO Auto-generated method stub

			}
		});

		return m;
	}

	@Override
	protected void handleSpeciesTreeInvestigationEdgeSelect(int idEdgeToNode, Point point)
	{
		Window.alert("clicked on edge");

	}
}
