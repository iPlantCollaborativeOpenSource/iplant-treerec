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

	private static final String SEARCH_TYPE_BLAST = "blast";
	private static final String SEARCH_TYPE_GENE_NAME = "gene_name";
	private static final String SEARCH_TYPE_GO = "go";
	private static final String SEARCH_TYPE_FAMILY_ID = "family_id";

	private final int GRID_HEIGHT_NORMAL = 260;
	private final int GRID_HEIGHT_SHORT = 142;

	private ListBox selectSearchType;

	private VerticalPanel pnlSearch;

	private SimpleSearchPanel pnlSearchSimple;

	private BLASTSearchPanel pnlSearchBlast;

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
	}

	private void showTextAreaSearchInput()
	{
		removeWidgetFromLayoutContainer(pnlSearch, pnlSearchSimple);
		pnlSearch.add(pnlSearchBlast);
		pnlSearch.layout();

		pnlSearchBlast.setFocusWidget();
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

		ret.addItem("BLAST", SEARCH_TYPE_BLAST);
		ret.addItem("Gene Name", SEARCH_TYPE_GENE_NAME);
		ret.addItem("Gene Ontology", SEARCH_TYPE_GO);
		ret.addItem("Gene Family ID", SEARCH_TYPE_FAMILY_ID);

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

		// XXX delete me
		ret += "\"sequenceType\": \"protein\",";
		
		ret += "\"sequence\": \"" + JsonUtil.escapeNewLine(pnlSearchBlast.getSearchTerms()) + "\"";

		ret += "}";

		return ret;
	}

	private void performBLASTSearch(final String term)
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

				if(type.equals(SEARCH_TYPE_GENE_NAME))
				{
					performGeneIdSearch(pnlSearchSimple.getSearchTerm());
				}
				else if(type.equals(SEARCH_TYPE_BLAST))
				{
					performBLASTSearch(pnlSearchBlast.getSearchTerms());
				}
				else if(type.equals(SEARCH_TYPE_GO))
				{
					performGoTermSearch(pnlSearchSimple.getSearchTerm());
				}
				else if(type.equals(SEARCH_TYPE_FAMILY_ID))
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
		ret.add(pnlSearchBlast);

		return ret;
	}

	private void compose()
	{
		pnlSearch = initSearchPanel();
	
		ContentPanel pnlInner = new ContentPanel();
		pnlInner.setHeading("Search");
		
		pnlInner.add(pnlSearch);
		
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
					
					String err = "Search failed for term: " + term;
					MessageBox.alert("Error", err, null);					
				}

				@Override
				public void onSuccess(String result)
				{					
					searchComplete();
					showResultsWindow("Results for term " + term + ":", result);
				}
			};
		}
	}

	// BLAST search panel - contains text area, search button and fields for supported
	// BLAST search params
	class BLASTSearchPanel extends VerticalPanel
	{
		private static final String TR_BLAST_SEARCH_AREA_ID = "idTRSearchField";

		private SearchTextArea areaSearch;

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

		private void init()
		{			
			areaSearch = buildSearchArea();
		}

		private void compose()
		{
			// add type selection
			add(new Label("Enter protein or nucleotide sequence for gene of interest below:"));

			// add search components
			HorizontalPanel panelInner = new HorizontalPanel();

			TableData td = buildSearchTable();

			panelInner.add(areaSearch, td);
			panelInner.add(buildSearchButton(), td);

			add(panelInner);
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
					
					String err = "Search failed for term: " + pnlSearchBlast.getSearchTerms();
					MessageBox.alert("Error", err, null);					
				}

				@Override
				public void onSuccess(String result)
				{
					searchComplete();
					showResultsWindow("Results for BLAST search for entered sequence:", result);
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
	
	private void showResultsWindow(String heading, String results) {
		new TRSearchResultsWindow(heading, results, cmdView).show();
	}
}
