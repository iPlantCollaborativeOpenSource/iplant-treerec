package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;
import java.util.List;

import org.iplantc.core.broadcaster.shared.BroadcastCommand;
import org.iplantc.core.broadcaster.shared.Broadcaster;
import org.iplantc.phyloviewer.client.layout.JsLayoutCladogram;
import org.iplantc.phyloviewer.client.tree.viewer.DetailView;
import org.iplantc.phyloviewer.client.tree.viewer.model.JsDocument;
import org.iplantc.phyloviewer.shared.model.Document;
import org.iplantc.tr.demo.client.events.GeneTreeInvestigationNodeSelectEvent;
import org.iplantc.tr.demo.client.events.GeneTreeInvestigationNodeSelectEventHandler;
import org.iplantc.tr.demo.client.events.GeneTreeNavNodeSelectEvent;
import org.iplantc.tr.demo.client.events.GeneTreeNavNodeSelectEventHandler;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationEdgeSelectEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationEdgeSelectEventHandler;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationNodeSelectEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationNodeSelectEventHandler;
import org.iplantc.tr.demo.client.events.SpeciesTreeNavNodeSelectEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeNavNodeSelectEventHandler;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOutEvent;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOutEventHandler;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOverEvent;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOverEventHandler;
import org.iplantc.tr.demo.client.utils.PanelHelper;

import com.extjs.gxt.ui.client.event.ButtonEvent;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.util.Point;
import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.extjs.gxt.ui.client.widget.button.Button;
import com.extjs.gxt.ui.client.widget.toolbar.FillToolItem;
import com.extjs.gxt.ui.client.widget.toolbar.ToolBar;
import com.google.gwt.event.shared.EventBus;
import com.google.gwt.event.shared.HandlerRegistration;

/**
 * Abstract tree channel panel.
 * 
 * @author amuir
 * 
 */
public abstract class TreeChannelPanel extends ContentPanel
{
	protected DetailView treeView;

	private final String jsonTree;
	private final String layoutTree;

	protected EventBus eventbus;

	protected String geneFamName;

	protected List<HandlerRegistration> handlers;

	/**
	 * Instantiate from an event bus, caption, id, tree and layout
	 * 
	 * @param eventbus event bus for firing/receiving events.
	 * @param caption text to display in panel heading.
	 * @param id unique id for this panel.
	 * @param jsonTree tree data.
	 * @param layoutTree layout data.
	 * @param geneFamName gene family id
	 */
	public TreeChannelPanel(final EventBus eventbus, final String caption, final String id,
			final String jsonTree, final String layoutTree, String geneFamId)
	{
		this.eventbus = eventbus;
		this.jsonTree = jsonTree;
		this.layoutTree = layoutTree;
		this.geneFamName = geneFamId;

		init(caption, id);

		initListeners();

		compose();
	}

	private void init(final String caption, final String id)
	{
		setStyleAttribute("margin", "5px");
		// setScrollMode(Scroll.AUTO);
		setHeading(caption);

		setId(id);

		handlers = new ArrayList<HandlerRegistration>();
	}

	private final static native JsDocument getDocument(String json) /*-{
		return eval(json);
	}-*/;

	private final static native JsLayoutCladogram getLayout(String json) /*-{
		return eval(json);
	}-*/;

	private DetailView buildTreeView()
	{
		DetailView ret = null; // assume failure

		// we need at least a tree and a layout for rendering
		if(jsonTree != null && layoutTree != null)
		{
			ret = new DetailView(800, 600, null);

			JsDocument doc = getDocument("(" + jsonTree + ") ");
			JsLayoutCladogram layout = getLayout("(" + layoutTree + ")");

			// build our document
			Document document = new Document();
			document.setTree(doc.getTree());
			document.setStyleMap(doc.getStyleMap());
			document.setLayout(layout);

			// set the document - if you don't do this TREES WONT APPEAR!
			ret.setDocument(document);
		}

		return ret;
	}

	/**
	 * Sets our command for broadcasting JSON messages.
	 * 
	 * @param cmdBroadcast command for broadcasting JSON messages.
	 */
	public void setBroadcastCommand(BroadcastCommand cmdBroadcast)
	{
		if(treeView != null)
		{
			treeView.setBroadcastCommand(cmdBroadcast);
		}
	}

	/**
	 * Retrieve our member broadcaster.
	 * 
	 * @return our broadcaster. In this case it is a tree rendering panel.
	 */
	public Broadcaster getBroadcaster()
	{
		return treeView;
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

	private void compose()
	{
		setTopComponent(buildToolbar());
		treeView = buildTreeView();

		if(treeView != null)
		{
			add(treeView);
			treeView.requestRender();
		}
	}

	/**
	 * Handle when a node is clicked in the gene tree while in investigation mode.
	 * 
	 * @param idNode unique id of clicked node.
	 * @param point absolute point where user clicked in the screen
	 */
	protected abstract void handleGeneTreeInvestigationNodeSelect(int idNode, Point point);

	/**
	 * Handle when a node is clicked in the gene tree while in navigation mode.
	 * 
	 * @param idNode unique id of clicked node.
	 * @param point absolute point where user clicked in the screen
	 */
	protected abstract void handleGeneTreeNavNodeSelect(int idNode, Point point);

	/**
	 * Handle when a node is clicked in the species tree while in investigation mode.
	 * 
	 * @param idNode unique id of clicked node.
	 * @param point absolute point where user clicked in the screen
	 */
	protected abstract void handleSpeciesTreeInvestigationNodeSelect(int idNode, Point point);

	/**
	 * Handle when a node is clicked in the species tree while in navigation mode.
	 * 
	 * @param idNode unique id of clicked node.
	 * @param point absolute point where user clicked in the screen
	 */
	protected abstract void handleSpeciesTreeNavNodeSelect(int idNode, Point point);

	/**
	 * Handle when a node is clicked in the species tree while in navigation mode.
	 * 
	 * @param idEdgeToNode unique id of node resulting from the edge.
	 * @param point absolute point where user clicked in the screen
	 */
	protected abstract void handleSpeciesTreeInvestigationEdgeSelect(int idEdgeToNode, Point point);

	/**
	 * Handle when mouse hover over a node.
	 * 
	 * @param idEdgeToNode unique id of node resulting from the edge.
	 * @param point absolute point where user clicked in the screen
	 */
	protected void handleMouseOver(int idEdgeToNode, Point point)
	{
		setStyleAttribute("cursor", "pointer");
	}

	/**
	 * Handle when mouse moves out of a node
	 * 
	 * @param idEdgeToNode unique id of node resulting from the edge.
	 * @param point absolute point where user clicked in the screen
	 */
	protected void handleMouseOut(int idEdgeToNode, Point point)
	{
		setStyleAttribute("cursor", "default");
	}

	/**
	 * Initialize our event listeners and add them to the event bus.
	 */
	protected void initListeners()
	{
		if(eventbus != null)
		{
			handlers.add(eventbus.addHandler(GeneTreeInvestigationNodeSelectEvent.TYPE,
					new GeneTreeInvestigationNodeSelectEventHandler()
					{
						@Override
						public void onFire(GeneTreeInvestigationNodeSelectEvent event)
						{
							handleGeneTreeInvestigationNodeSelect(event.getNodeId(), event.getPoint());
						}
					}));

			handlers.add(eventbus.addHandler(GeneTreeNavNodeSelectEvent.TYPE,
					new GeneTreeNavNodeSelectEventHandler()
					{
						@Override
						public void onFire(GeneTreeNavNodeSelectEvent event)
						{
							handleGeneTreeNavNodeSelect(event.getNodeId(), event.getPoint());
						}
					}));

			handlers.add(eventbus.addHandler(SpeciesTreeInvestigationNodeSelectEvent.TYPE,
					new SpeciesTreeInvestigationNodeSelectEventHandler()
					{
						@Override
						public void onFire(SpeciesTreeInvestigationNodeSelectEvent event)
						{
							handleSpeciesTreeInvestigationNodeSelect(event.getNodeId(), event.getPoint());
						}
					}));

			handlers.add(eventbus.addHandler(SpeciesTreeNavNodeSelectEvent.TYPE,
					new SpeciesTreeNavNodeSelectEventHandler()
					{
						@Override
						public void onFire(SpeciesTreeNavNodeSelectEvent event)
						{
							handleSpeciesTreeNavNodeSelect(event.getNodeId(), event.getPoint());
						}
					}));

			handlers.add(eventbus.addHandler(SpeciesTreeInvestigationEdgeSelectEvent.TYPE,
					new SpeciesTreeInvestigationEdgeSelectEventHandler()
					{
						@Override
						public void onFire(SpeciesTreeInvestigationEdgeSelectEvent event)
						{
							handleSpeciesTreeInvestigationEdgeSelect(event.getIdEdgeToNode(), event
									.getPoint());

						}
					}));

			handlers.add(eventbus.addHandler(TreeNodeMouseOverEvent.TYPE,
					new TreeNodeMouseOverEventHandler()
					{

						@Override
						public void onMouseOver(TreeNodeMouseOverEvent e)
						{
							handleMouseOver(e.getIdNode(), e.getPoint());

						}
					}));

			handlers.add(eventbus.addHandler(TreeNodeMouseOutEvent.TYPE,
					new TreeNodeMouseOutEventHandler()
					{
						@Override
						public void onMouseOut(TreeNodeMouseOutEvent e)
						{
							handleMouseOut(e.getIdNode(), e.getPoint());
						}
					}));
		}
	}

	public void cleanup()
	{
		// unregister
		for(HandlerRegistration reg : handlers)
		{
			reg.removeHandler();
		}

		// clear our list
		handlers.clear();
	}
}
