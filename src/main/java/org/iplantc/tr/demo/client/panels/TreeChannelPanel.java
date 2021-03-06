package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;
import java.util.List;

import org.iplantc.core.broadcaster.shared.BroadcastCommand;
import org.iplantc.core.broadcaster.shared.Broadcaster;
import org.iplantc.phyloviewer.client.layout.JsLayoutCladogram;
import org.iplantc.phyloviewer.client.tree.viewer.DetailView;
import org.iplantc.phyloviewer.client.tree.viewer.model.JsDocument;
import org.iplantc.phyloviewer.shared.model.Document;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOutEvent;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOutEventHandler;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOverEvent;
import org.iplantc.tr.demo.client.events.TreeNodeMouseOverEventHandler;

import com.extjs.gxt.ui.client.util.Point;
import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.google.gwt.event.shared.EventBus;
import com.google.gwt.event.shared.HandlerRegistration;

/**
 * Basic tree channel panel.
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

	protected List<HandlerRegistration> handlers;

	int windowWidth=1600;
	int windowHeight=800;
	
	/**
	 * Instantiate from an event bus, caption, id, tree and layout
	 * 
	 * @param eventbus event bus for firing/receiving events.
	 * @param caption text to display in panel heading.
	 * @param id unique id for this panel.
	 * @param jsonTree tree data.
	 * @param layoutTree layout data.
	 */
	public TreeChannelPanel(final EventBus eventbus, final String caption, final String id,
			final String jsonTree, final String layoutTree, int w, int h)
	{
		this.eventbus = eventbus;
		this.jsonTree = jsonTree;
		this.layoutTree = layoutTree;
		if(w>0 && h>0) {
			windowWidth =w;
			windowHeight=h;
		}
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

	public void resizeView(int w , int h){
		treeView.resize(w-((int)w/2)-30, h-200);
		treeView.requestRender();
		treeView.zoomToFit();
	}
	
	public void setInitialTreeSizes(int w, int h) {
		windowWidth =w;
		windowHeight=h;
	}
	
	private DetailView buildTreeView()
	{
		DetailView ret = null; // assume failure

		// we need at least a tree and a layout for rendering
		if(jsonTree != null && layoutTree != null)
		{
			ret = new DetailView(windowWidth-((int)windowWidth/2)-30, windowHeight-200);

			JsDocument doc = getDocument("(" + jsonTree + ") ");
			JsLayoutCladogram layout = getLayout("(" + layoutTree + ")");

			// build our document
			Document document = new Document();
			document.setTree(doc.getTree());
			document.setStyleMap(doc.getStyleMap());
			document.setLayout(layout);

			// set the document - if you don't do this TREES WONT APPEAR!
			ret.setDocument(document);
			ret.addEventFilter(DetailView.DrawableType.Line);
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

	/**
	 * Display our tree view.
	 */
	protected void compose()
	{
		treeView = buildTreeView();

		if(treeView != null)
		{
			add(treeView);
			treeView.requestRender();
		}
	}

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

	/**
	 * Release unneeded resources.
	 */
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
