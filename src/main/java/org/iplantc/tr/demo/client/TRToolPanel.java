package org.iplantc.tr.demo.client;

import java.util.ArrayList;
import java.util.List;

import org.iplantc.tr.demo.client.images.Resources;

import com.extjs.gxt.ui.client.Style.HorizontalAlignment;
import com.extjs.gxt.ui.client.Style.SelectionMode;
import com.extjs.gxt.ui.client.event.BaseEvent;
import com.extjs.gxt.ui.client.event.ButtonEvent;
import com.extjs.gxt.ui.client.event.ComponentEvent;
import com.extjs.gxt.ui.client.event.Events;
import com.extjs.gxt.ui.client.event.KeyListener;
import com.extjs.gxt.ui.client.event.Listener;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.store.ListStore;
import com.extjs.gxt.ui.client.widget.Component;
import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.extjs.gxt.ui.client.widget.HorizontalPanel;
import com.extjs.gxt.ui.client.widget.Label;
import com.extjs.gxt.ui.client.widget.LayoutContainer;
import com.extjs.gxt.ui.client.widget.MessageBox;
import com.extjs.gxt.ui.client.widget.VerticalPanel;
import com.extjs.gxt.ui.client.widget.button.Button;
import com.extjs.gxt.ui.client.widget.form.TextArea;
import com.extjs.gxt.ui.client.widget.form.TextField;
import com.extjs.gxt.ui.client.widget.grid.ColumnConfig;
import com.extjs.gxt.ui.client.widget.grid.ColumnModel;
import com.extjs.gxt.ui.client.widget.grid.Grid;
import com.extjs.gxt.ui.client.widget.layout.TableData;
import com.extjs.gxt.ui.client.widget.toolbar.FillToolItem;
import com.extjs.gxt.ui.client.widget.toolbar.ToolBar;
import com.google.gwt.core.client.JsArray;
import com.google.gwt.event.dom.client.ChangeEvent;
import com.google.gwt.event.dom.client.ChangeHandler;
import com.google.gwt.event.dom.client.KeyCodes;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
import com.google.gwt.json.client.JSONValue;
import com.google.gwt.user.client.rpc.AsyncCallback;
import com.google.gwt.user.client.ui.AbstractImagePrototype;
import com.google.gwt.user.client.ui.ListBox;
import com.google.gwt.user.client.ui.Widget;

public class TRToolPanel extends VerticalPanel
{
	private static final String TR_SEARCH_TYPE_LIST_BOX_ID = "idTRSearchTypeSelection";
	private static final String TR_VIEW_BTN_ID = "idTRDataViewBtn";

	private static final String SEARCH_TYPE_GENE_CLUSTER = "gene_cluster";
	private static final String SEARCH_TYPE_BLAST = "blast";
	private static final String SEARCH_TYPE_GO_TERM = "go_term";
	private static final String SEARCH_TYPE_GO_ACCESSION = "go_accession";

	private final int GRID_HEIGHT_NORMAL = 260;
	private final int GRID_HEIGHT_SHORT = 142;

	private ListBox selectSearchType;

	private VerticalPanel pnlSearch;

	private SimpleSearchPanel pnlSearchSimple;

	private BLASTSearchPanel pnlSearchBlast;

	private ContentPanel pnlGrid;
	private Grid<TRSearchResult> gridResults;

	private ArrayList<Button> buttons;

	private SearchServiceAsync searchService;
	private ClientCommand cmdView;
	private ClientCommand cmdSearchBegin;
	private ClientCommand cmdSearchComplete;
	
	
	public TRToolPanel(SearchServiceAsync searchService,ClientCommand cmdView, ClientCommand cmdSearchBegin, ClientCommand cmdSearchComplete)
	{
		this.searchService = searchService;
		this.cmdView = cmdView;
		this.cmdSearchBegin = cmdSearchBegin;
		this.cmdSearchComplete = cmdSearchComplete;
		
		init();
		
		compose();
	}

	private void init()
	{
		setSpacing(5);		
	}

	private void removeWidgetFromLayoutContainer(LayoutContainer pnl, Component component)
	{
		List<Component> components = pnl.getItems();

		for(Component test : components)
		{
			if(test == component)
			{
				pnl.remove(component);
				break;
			}
		}
	}

	private void showTextFieldSearchInput()
	{
		removeWidgetFromLayoutContainer(pnlSearch, pnlSearchBlast);
		pnlSearch.add(pnlSearchSimple);
		pnlSearch.layout();

		pnlSearchSimple.setFocusWidget();

		gridResults.setHeight(GRID_HEIGHT_NORMAL);
	}

	private void showTextAreaSearchInput()
	{
		removeWidgetFromLayoutContainer(pnlSearch, pnlSearchSimple);
		pnlSearch.add(pnlSearchBlast);
		pnlSearch.layout();

		pnlSearchBlast.setFocusWidget();

		gridResults.setHeight(GRID_HEIGHT_SHORT);
	}

	private void updateSelection()
	{
		String value = selectSearchType.getValue(selectSearchType.getSelectedIndex());

		if(value.equals(SEARCH_TYPE_BLAST))
		{
			showTextAreaSearchInput();
		}
		else
		{
			showTextFieldSearchInput();
		}
	}

	private ListBox initSearchTypeSelection()
	{
		ListBox ret = new ListBox();

		ret.getElement().setId(TR_SEARCH_TYPE_LIST_BOX_ID);

		ret.addItem("Gene Identifier", SEARCH_TYPE_GENE_CLUSTER);
		ret.addItem("BLAST", SEARCH_TYPE_BLAST);
		ret.addItem("GO Term", SEARCH_TYPE_GO_TERM);
		ret.addItem("GO Accession", SEARCH_TYPE_GO_ACCESSION);

		// handle selection changed
		ret.addChangeHandler(new ChangeHandler()
		{
			@Override
			public void onChange(ChangeEvent ce)
			{
				updateSelection();
			}
		});

		return ret;
	}

	private VerticalPanel buildSearchTypeSelectionPanel()
	{
		VerticalPanel ret = new VerticalPanel();

		selectSearchType = initSearchTypeSelection();

		ret.add(new Label("Search Type:"));
		ret.add(selectSearchType);

		return ret;
	}

	private void updateSearchPanelCaption(String term)
	{
		if(pnlGrid != null)
		{
			pnlGrid.setHeading("Results for:" + term);
		}
	}

	private boolean isEmpty(JSONValue in)
	{
		boolean ret = true; // assume we have an empty value

		if(in != null)
		{
			String test = in.toString();

			if(test.length() > 0 && !test.equals("[]"))
			{
				ret = false;
			}
		}

		return ret;
	}

	private void clearGrid()
	{
		ListStore<TRSearchResult> store = gridResults.getStore();

		store.removeAll();
	}

	private JSONValue parseFamilies(JSONObject jsonObj)
	{
		JSONValue ret = null;
	
		//drill down to families array
		JSONValue val = jsonObj.get("data");
		
		if(val != null)
		{
			val = ((JSONObject)val).get("item");

			if(val != null)
			{
				ret = ((JSONObject)val).get("families");
			}
		}
		
		return ret;
	}
	
	private void updateSearchGrid(String json)
	{
		ListStore<TRSearchResult> store = gridResults.getStore();

		clearGrid();

		if(json != null)
		{
			JSONObject jsonObj = (JSONObject)JSONParser.parse(json);
			JSONValue valItems = parseFamilies(jsonObj);

			if(!isEmpty(valItems))
			{
				JsArray<JsTRSearchResult> arr = JsonUtil.asArrayOf(valItems.toString());

				for(int i = 0,len = arr.length();i < len;i++)
				{
					TRSearchResult item = new TRSearchResult(arr.get(i));
					store.add(item);
				}
			}
		}
	}

	private void performGeneIdSearch(final String term)
	{
		if(searchService != null && term != null)
		{
			searchService.doGeneIdSearch(term, pnlSearchSimple.getSearchCallback(term));
		}
	}

	private void performGoTermSearch(final String term)
	{
		if(term != null)
		{
			searchService.doGoTermSearch(term, pnlSearchSimple.getSearchCallback(term));
		}
	}

	private void performGoAccessionSearch(final String term)
	{
		if(term != null)
		{
			searchService.doGoAccessionSearch(term, pnlSearchSimple.getSearchCallback(term));
		}
	}

	private String buildBLASTJson()
	{
		String ret = "{";

		ret += "\"sequenceType\": \"" + pnlSearchBlast.getSearchType() + "\", ";
		ret += "\"sequence\": \"" + JsonUtil.escapeNewLine(pnlSearchBlast.getSearchTerms()) + "\"";

		ret += "}";

		return ret;
	}

	private void performBLASTSearch()
	{
		String json = buildBLASTJson();

		searchService.doBLASTSearch(json, pnlSearchBlast.getSearchCallback());
	}

	private Button buildSearchButton()
	{
		return PanelHelper.buildButton("idTRSearchBtn", "Search", new SelectionListener<ButtonEvent>()
		{
			@Override
			public void componentSelected(ButtonEvent ce)
			{
				searchBegin();
				
				String type = selectSearchType.getValue(selectSearchType.getSelectedIndex());

				if(type.equals(SEARCH_TYPE_GENE_CLUSTER))
				{
					performGeneIdSearch(pnlSearchSimple.getSearchTerm());
				}
				else if(type.equals(SEARCH_TYPE_BLAST))
				{
					performBLASTSearch();
				}
				else if(type.equals(SEARCH_TYPE_GO_TERM))
				{
					performGoTermSearch(pnlSearchSimple.getSearchTerm());
				}
				else if(type.equals(SEARCH_TYPE_GO_ACCESSION))
				{
					performGoAccessionSearch(pnlSearchSimple.getSearchTerm());
				}
			}
		});
	}

	private TableData buildSearchTable()
	{
		TableData ret = new TableData();

		ret.setPadding(3);
		ret.setHorizontalAlign(HorizontalAlignment.RIGHT);

		return ret;
	}

	private VerticalPanel initSearchPanel()
	{
		VerticalPanel ret = new VerticalPanel();

		ret.setSpacing(5);
		ret.setBorders(true);
		ret.setStyleAttribute("background-color", "#EDEDED");
		
		pnlSearchSimple = new SimpleSearchPanel();
		pnlSearchBlast = new BLASTSearchPanel();

		ret.add(buildSearchTypeSelectionPanel());
		ret.add(pnlSearchSimple);

		return ret;
	}

	// build column with custom renderer
	private ColumnConfig buildConfig(String id, String caption, int width, HorizontalAlignment alignment)
	{
		ColumnConfig ret = new ColumnConfig(id, caption, width);

		ret.setMenuDisabled(true);
		ret.setSortable(false);
		ret.setAlignment(alignment);

		return ret;
	}

	private ColumnModel buildColumnModel()
	{
		List<ColumnConfig> config = new ArrayList<ColumnConfig>();

		config.add(buildConfig("name", "Name", 140, HorizontalAlignment.LEFT));
		config.add(buildConfig("goAnnotations", "GO Annotations", 200,
				HorizontalAlignment.LEFT));
		config.add(buildConfig("numGenes", "# of Genes", 80, HorizontalAlignment.CENTER));
		config
				.add(buildConfig("numSpecies", "# of Species", 80,
						HorizontalAlignment.CENTER));

		return new ColumnModel(config);
	}

	private Grid<TRSearchResult> buildResultsGrid()
	{
		ListStore<TRSearchResult> store = new ListStore<TRSearchResult>();

		final ColumnModel cm = buildColumnModel();

		final Grid<TRSearchResult> ret = new Grid<TRSearchResult>(store, cm);

		ret.setSize(500, GRID_HEIGHT_NORMAL);
		ret.getSelectionModel().setSelectionMode(SelectionMode.MULTI);
		ret.setAutoExpandColumn("name");

		ret.getView().setEmptyText("No results to display.");

		ret.getSelectionModel().addListener(Events.SelectionChange, new Listener<BaseEvent>()
		{
			@Override
			public void handleEvent(BaseEvent be)
			{
				if(ret.getSelectionModel().getSelectedItems().size() == 0)
				{
					disableButton(TR_VIEW_BTN_ID);
				}
				else
				{
					enableButton(TR_VIEW_BTN_ID);
				}
			}
		});

		return ret;
	}

	private String getSelectedGeneInfo()
	{
		String ret = null; // assume failure

		TRSearchResult result = gridResults.getSelectionModel().getSelectedItem();

		// do we have a selection?
		if(result != null)
		{
			ret = result.getName();
		}

		return ret;
	}

	private void launchViewers()
	{
		String name = getSelectedGeneInfo();

		// do we have any genes to view
		if(name != null)
		{
			cmdView.execute(name);
		}
	}

	private void addButton(String caption, String id, AbstractImagePrototype icon,
			SelectionListener<ButtonEvent> listener)
	{
		Button btn = new Button(caption, icon, listener);

		btn.setId(id);
		btn.setEnabled(false);
		btn.setHeight(23);

		buttons.add(btn);
	}

	private void addButtons()
	{
		buttons = new ArrayList<Button>();

		addButton("View", TR_VIEW_BTN_ID, AbstractImagePrototype.create(Resources.ICONS
				.listItems()), new SelectionListener<ButtonEvent>()
		{
			@Override
			public void componentSelected(ButtonEvent ce)
			{
				launchViewers();
			}
		});
	}

	private void enableButton(String id)
	{
		for(Button button : buttons)
		{
			if(button.getId().equals(id))
			{
				button.enable();
				pnlGrid.layout();
				break;
			}
		}
	}

	private void disableButton(String id)
	{
		for(Button button : buttons)
		{
			if(button.getId().equals(id))
			{
				button.disable();
				pnlGrid.layout();
				break;
			}
		}
	}

	private ToolBar buildButtonBar()
	{
		ToolBar ret = new ToolBar();

		ret.add(new FillToolItem());
		addButtons();

		// add all buttons to our toolbar
		for(Button btn : buttons)
		{
			ret.add(btn);
		}

		return ret;
	}

	private ContentPanel buildResultsGridPanel()
	{
		ContentPanel ret = new ContentPanel();

		ret.setHeading("Search Results");
		ret.setBottomComponent(buildButtonBar());

		gridResults = buildResultsGrid();

		ret.add(gridResults);

		return ret;
	}

	private void compose()
	{
		pnlSearch = initSearchPanel();
		pnlGrid = buildResultsGridPanel();
	
		ContentPanel pnlInner = new ContentPanel();
		pnlInner.setHeading("Search");
		
		pnlInner.add(pnlSearch);
		pnlInner.add(pnlGrid);
		
		add(pnlInner);
	}

	public Widget getFocusWidget()
	{
		return pnlSearchSimple.getFocusWidget();
	}

	private void searchBegin()
	{
		if(cmdSearchBegin != null)
		{
			cmdSearchBegin.execute(null);
		}
	}
	
	private void searchComplete()
	{
		if(cmdSearchComplete != null)
		{
			cmdSearchComplete.execute(null);
		}
	}
	
	// simple search panel - contains text field and search button
	class SimpleSearchPanel extends HorizontalPanel
	{
		private static final String TR_SEARCH_FIELD_ID = "idTRSearchField";

		private TextField<String> entrySearch;

		public SimpleSearchPanel()
		{
			init();
			compose();
		}

		private void init()
		{			
			entrySearch = buildSearchEntry();
		}

		private void compose()
		{
			TableData td = buildSearchTable();

			add(entrySearch, td);
			add(buildSearchButton(), td);
		}

		private TextField<String> buildSearchEntry()
		{
			final TextField<String> ret = new TextField<String>();

			ret.setId(TR_SEARCH_FIELD_ID);
			ret.setWidth(290);
			ret.setSelectOnFocus(true);
			ret.addKeyListener(new KeyListener()
			{
				public void componentKeyUp(ComponentEvent event)
				{
					if(event.getKeyCode() == KeyCodes.KEY_ENTER)
					{
						performGeneIdSearch(ret.getValue());
					}
				}
			});

			return ret;
		}

		public String getSearchTerm()
		{
			return entrySearch.getValue();
		}

		public void setFocusWidget()
		{
			if(entrySearch != null)
			{
				entrySearch.focus();
			}
		}

		public TextField<String> getFocusWidget()
		{
			return entrySearch;
		}

		public AsyncCallback<String> getSearchCallback(final String term)
		{
			return new AsyncCallback<String>()
			{
				@Override
				public void onFailure(Throwable arg0)
				{					
					searchComplete();
					clearGrid();
					updateSearchPanelCaption(term);
					
					String err = "Search failed for term: " + term;
					MessageBox.alert("Error", err, null);					
				}

				@Override
				public void onSuccess(String result)
				{					
					searchComplete();
					disableButton(TR_VIEW_BTN_ID);
					updateSearchPanelCaption(term);
					updateSearchGrid(result);
				}
			};
		}
	}

	// BLAST search panel - contains text area, search button and fields for supported
	// BLAST search params
	class BLASTSearchPanel extends VerticalPanel
	{
		private static final String TR_BLAST_SEARCH_AREA_ID = "idTRSearchField";
		private static final String TR_BLAST_TYPE_SELECTION_ID = "idTRBlastTypeSelection";
		private static final String BLAST_TYPE_GENE_PROTEIN = "protein";
		private static final String BLAST_TYPE_NUCLEOTIDE = "nucleotide";

		private SearchTextArea areaSearch;
		private ListBox selectBlastType;

		public BLASTSearchPanel()
		{
			init();

			compose();
		}

		private SearchTextArea buildSearchArea()
		{
			final SearchTextArea ret = new SearchTextArea();

			ret.setSize(380, 99);
			ret.setSelectOnFocus(true);
			ret.setId(TR_BLAST_SEARCH_AREA_ID);

			return ret;
		}

		private ListBox buildTypeSelection()
		{
			ListBox ret = new ListBox();

			ret.getElement().setId(TR_BLAST_TYPE_SELECTION_ID);

			ret.addItem("Protein", BLAST_TYPE_GENE_PROTEIN);
			ret.addItem("Nucleotide", BLAST_TYPE_NUCLEOTIDE);

			return ret;
		}

		private void init()
		{			
			selectBlastType = buildTypeSelection();
			areaSearch = buildSearchArea();
		}

		private void compose()
		{
			// add type selection
			add(new Label("BLAST Query Sequence Type:"));
			add(selectBlastType);

			// add search components
			HorizontalPanel panelInner = new HorizontalPanel();

			TableData td = buildSearchTable();

			panelInner.add(areaSearch, td);
			panelInner.add(buildSearchButton(), td);

			add(panelInner);
		}

		public String getSearchType()
		{
			return selectBlastType.getValue(selectBlastType.getSelectedIndex());
		}

		public String getSearchTerms()
		{
			return areaSearch.getValue();
		}

		public void setFocusWidget()
		{
			if(areaSearch != null)
			{
				areaSearch.focus();
			}
		}

		public SearchTextArea getFocusWidget()
		{
			return areaSearch;
		}

		public AsyncCallback<String> getSearchCallback()
		{
			return new AsyncCallback<String>()
			{
				@Override
				public void onFailure(Throwable arg0)
				{
					searchComplete();
					clearGrid();
					updateSearchPanelCaption(getSearchType());
					
					String err = "Search failed for term: " + getSearchType();
					MessageBox.alert("Error", err, null);					
				}

				@Override
				public void onSuccess(String result)
				{
					searchComplete();
					disableButton(TR_VIEW_BTN_ID);
					updateSearchPanelCaption(pnlSearchBlast.getSearchType());
					updateSearchGrid(result);
				}
			};
		}
		
		class SearchTextArea extends TextArea
		{
			@Override
			protected void afterRender()
			{
				super.afterRender();
				
				el().setElementAttribute("spellcheck", "false");
			}
		}
	}	
}
