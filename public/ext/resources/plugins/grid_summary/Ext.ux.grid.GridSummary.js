Ext.ns("Ext.ux.grid.GridSummary"); // namespace Ext.ux.grid.GridSummary
Ext.ns("Ext.ux.grid.GridPanelWithSummary"); // namespace Ext.ux.grid.GridSummary
Ext.ns("Ext.ux.data.StoreWithSummary"); // namespace Ext.ux.grid.GridSummary
Ext.ns("Ext.ux.data.JsonReaderWithSummary"); // namespace Ext.ux.grid.GridSummary


Ext.ux.grid.GridPanelWithSummary = function(config) {
    // Your preprocessing here
	Ext.ux.grid.GridPanelWithSummary.superclass.constructor.apply(this, arguments);
    // Your postprocessing here
};

Ext.extend(Ext.ux.grid.GridPanelWithSummary, Ext.grid.GridPanel, {
});

Ext.ux.data.StoreWithSummary = function(config) {
    // Your preprocessing here
    //console.log('StoreWithSummary -- call superclass constructor')
    this.summary = {json : {}};
    Ext.ux.data.StoreWithSummary.superclass.constructor.apply(this, arguments);    
}


Ext.extend(Ext.ux.data.StoreWithSummary, Ext.data.Store, {        
        loadRecords : function(o, options, success){
          //console.log('my loadRecords')
          this.summary = o.summary
          //console.log('my loadRecords -- call superclass')  
          Ext.ux.data.StoreWithSummary.superclass.loadRecords.call(this, o, options, success);
          //console.log('end my loadRecords')
        }
});


Ext.ux.data.JsonReaderWithSummary = function(config) {
    // Your preprocessing here
    Ext.ux.data.JsonReaderWithSummary.superclass.constructor.apply(this, arguments);
    // Your postprocessing here
};

Ext.extend(Ext.ux.data.JsonReaderWithSummary, Ext.data.JsonReader, {
  readRecords : function(o){
    //console.log('my readRecords');
    
    var s = this.meta;
    if (!this.ef) {
      if(s.summaryProperty) {
        this.getSummary = this.getJsonAccessor(s.summaryProperty);
				this.getPayTotals = this.getJsonAccessor(s.paytotalsProperty);
      }
    }
    //console.log('my readRecords: call superclass.readRecords');
    superResult = Ext.ux.data.JsonReaderWithSummary.superclass.readRecords.call(this, o);
    var Record = this.recordType,
    f = Record.prototype.fields, fi = f.items, fl = f.length;

    if(s.summaryProperty) {
      //console.log('had a summaryProperty: '+s.summaryProperty)
      var values = {};
      var summary = this.getSummary(o)
      //console.log('summary: '+summary)
      var id = -1; // RADAR
      //console.log('fl: '+fl)
      for(var j = 0; j < fl; j++){
        f = fi[j];
        //console.log('f: '+f)
        var v = this.ef[j](summary);
        //console.log('v: '+v)
        values[f.name] = f.convert((v !== undefined) ? v : f.defaultValue);
      }
      var record = new Record(values, id);
      record.json = summary;
      superResult['summary'] = record;

    }
    
    if(s.paytotalsProperty) {
      // console.log('had a paytotalProperty: '+s.paytotalsProperty)
      var values = {};
      var paytotals = this.getPayTotals(o)
      // console.log('paytotals: '+paytotals)
      var id = -1; // RADAR
      // console.log('fl: '+fl)
      for(var j = 0; j < fl; j++){
        f = fi[j];
        // console.log('f: '+f)
        var v = this.ef[j](paytotals);
        // console.log('v: '+v)
        values[f.name] = f.convert((v !== undefined) ? v : f.defaultValue);
      }
      var record = new Record(values, id);
      record.json = paytotals;
      superResult['paytotals'] = record;
    }

    //console.log('end my readRecords')
    return superResult;
  }
});


Ext.ux.grid.GridSummary = function(config) {
    Ext.apply(this, config);
};

Ext.extend(Ext.ux.grid.GridSummary, Ext.util.Observable, {
  useStoreSummary : false,
  
  init : function(grid) {
    this.grid = grid;
    this.cm = grid.getColumnModel();
    this.view = grid.getView();
    var v = this.view;

    v.onLayout = this.onLayout; // override GridView's onLayout() method

    v.afterMethod('render', this.refreshSummary, this);
    v.afterMethod('refresh', this.refreshSummary, this);
    v.afterMethod('syncScroll', this.syncSummaryScroll, this);
    v.afterMethod('onColumnWidthUpdated', this.doWidth, this);
    v.afterMethod('onAllColumnWidthsUpdated', this.doAllWidths, this);
    v.afterMethod('onColumnHiddenUpdated', this.doHidden, this);
    v.afterMethod('onUpdate', this.refreshSummary, this);
    v.afterMethod('onRemove', this.refreshSummary, this);

    // update summary row on store's add / remove / clear events
    grid.store.on('add', this.refreshSummary, this);
    grid.store.on('remove', this.refreshSummary, this);
    grid.store.on('clear', this.refreshSummary, this);

    if (!this.rowTpl) {
      //console.log('this.showlabels: '+this.showlabels)
      if (!this.showLabels){
        this.rowTpl = new Ext.Template(
          '<div class="x-grid3-summary-row x-grid3-gridsummary-row-offset">',
            '<table class="x-grid3-summary-table" border="0" cellspacing="0" cellpadding="0" style="{tstyle}">',
              '<tbody><tr>{cells}</tr></tbody>',
            '</table>',
          '</div>'
        );
      } else {
        this.rowTpl = new Ext.Template(
          '<div class="x-grid3-summary-row x-grid3-gridsummary-row-offset">',
            '<table class="x-grid3-summary-table" border="0" cellspacing="0" cellpadding="0" style="{tstyle}">',
              '<thead><tr>{labels}</tr></thead>',
              '<tbody><tr>{cells}</tr></tbody>',
            '</table>',
          '</div>'
        );
      }
      this.rowTpl.disableFormats = true;
    }
    this.rowTpl.compile();

    if (!this.cellTpl) {
      this.cellTpl = new Ext.Template(
        '<td class="x-grid3-col x-grid3-cell x-grid3-td-{id} {css}" style="{style}">',
          '<div class="x-grid3-cell-inner x-grid3-col-{id}" unselectable="on">{value}</div>',
        "</td>"
      );
      this.cellTpl.disableFormats = true;
    }
    this.cellTpl.compile();

    if (!this.labelTpl) {
      this.labelTpl = new Ext.Template(
        '<td class="x-grid3-hd x-grid3-cell x-grid3-td-{id} {css}" style="{style}">',
          '<div class="x-grid3-hd-inner x-grid3-hd-{id}" unselectable="on">{value}</div>',
        "</td>"
      );
      this.cellTpl.disableFormats = true;
    }
    this.cellTpl.compile();
    
    
  },

  calculate : function(rs, cs) {
    var data = {}, r, c, cfg = this.cm.config, cf;
    for (var j = 0, jlen = rs.length; j < jlen; j++) {
      r = rs[j];
      for (var i = 0, len = cs.length; i < len; i++) {
        c = cs[i];
        cf = cfg[i];
        if (cf && cf.summaryType) {
          data[c.name] = Ext.ux.grid.GridSummary.Calculations[cf.summaryType](data[c.name] || 0, r, c.name, data);
        }
      }
    }

    return data;
  },

  onLayout : function(vw, vh) {
    // note: this method is scoped to the GridView
    if (!this.grid.getGridEl().hasClass('x-grid-hide-gridsummary')) {
      // readjust gridview's height only if grid summary row is visible
      if( this.summary != undefined && vh != undefined) {
        this.scroller.setHeight(vh - this.summary.getHeight());
      }
    }
  },

  syncSummaryScroll : function() {
    var mb = this.view.scroller.dom;
    this.view.summaryWrap.dom.scrollLeft = mb.scrollLeft;
    this.view.summaryWrap.dom.scrollLeft = mb.scrollLeft; // second time for IE (1/2 time first fails, other browsers ignore)
  },
  doWidth : function(col, w, tw) {
    var s = this.view.summary.dom;
    s.firstChild.style.width = tw;
    s.firstChild.rows[0].childNodes[col].style.width = w;
  },

  doAllWidths : function(ws, tw) {
    //console.debugger;
    var s = this.view.summary.dom, wlen = ws.length;
    s.firstChild.style.width = tw;
    var rows = (this.showLabels ? 2 : 1);
    for (var i=0; i < rows; i++) {
      cells = s.firstChild.rows[i].childNodes;
      for (var j = 0; j < wlen; j++) {
        cells[j].style.width = ws[j];
      }
    }
  },

  doHidden : function(col, hidden, tw) {
    var s = this.view.summary.dom;
    var display = hidden ? 'none' : '';
    s.firstChild.style.width = tw;
    s.firstChild.rows[0].childNodes[col].style.display = display;
  },

  renderSummary : function(o, cs) {
    cs = cs || this.view.getColumnData();
    var cfg = this.cm.config;
    var buf = [], c, p = {}, la = {}, cf, last = cs.length-1, labels = [];

    for (var i = 0, len = cs.length; i < len; i++) {
      c = cs[i];
      cf = cfg[i];
      p.id = c.id;
      p.style = c.style;
      p.css = i == 0 ? 'x-grid3-cell-first ' : (i == last ? 'x-grid3-cell-last ' : '');
      la.id = c.id;
      la.style = c.style;
      la.css = i == 0 ? 'x-grid3-cell-first ' : (i == last ? 'x-grid3-cell-last ' : '');
      if (cf.summaryType || cf.summaryRenderer) {
        p.value = (cf.summaryRenderer || c.renderer)(o.data[c.name], p, o);
      } else {
        p.value = '';
      }
      if(this.labels && this.labels[c.name]) {
        la.value = this.labels[c.name];
        la.css = la.css + ' labelled';
      } else {
      //        la.value = c.name;
        la.value = '';
      }
      if (p.value == undefined || p.value === "") p.value = "&#160;";
      labels[labels.length] = this.labelTpl.apply(la);
      buf[buf.length] = this.cellTpl.apply(p);
    }

    return this.rowTpl.apply({
      tstyle: 'width:' + this.view.getTotalWidth() + ';',
      cells: buf.join(''),
      labels: labels.join('')
    });
  },

  refreshSummary : function() {
    //console.log('refreshSummary');
    var g = this.grid, ds = g.store;
    var cs = this.view.getColumnData();
    var rs = ds.getRange();
    var data;
    if(this.useStoreSummary){
      data = ds.summary.json
    } else {
      data = this.calculate(rs, cs);  
    }
    var buf = this.renderSummary({data: data}, cs);

    if (!this.view.summaryWrap) {
      this.view.summaryWrap = Ext.DomHelper.insertAfter(this.view.scroller, {
        tag: 'div',
        cls: 'x-grid3-gridsummary-row-inner'
      }, true);
    } else {
      this.view.summary.remove();
    }
    this.view.summary = this.view.summaryWrap.insertHtml('afterbegin', buf, true);
  },

  toggleSummary : function(visible) { // true to display summary row
    var el = this.grid.getGridEl();
    if (el) {
      if (visible === undefined) {
        visible = el.hasClass('x-grid-hide-gridsummary');
      }
      el[visible ? 'removeClass' : 'addClass']('x-grid-hide-gridsummary');

      this.view.layout(); // readjust gridview height
    }
  },

  getSummaryNode : function() {
    return this.view.summary
  }
  
});


Ext.ux.grid.GridSummary.Calculations = {
  'sum' : function(v, record, field) {
    return v + Ext.num(record.data[field], 0);
  },

  'count' : function(v, record, field, data) {
    return data[field+'count'] ? ++data[field+'count'] : (data[field+'count'] = 1);
  },

  'max' : function(v, record, field, data) {
    var v = record.data[field];
    var max = data[field+'max'] === undefined ? (data[field+'max'] = v) : data[field+'max'];
    return v > max ? (data[field+'max'] = v) : max;
  },

  'min' : function(v, record, field, data) {
    var v = record.data[field];
    var min = data[field+'min'] === undefined ? (data[field+'min'] = v) : data[field+'min'];
    return v < min ? (data[field+'min'] = v) : min;
  },

  'average' : function(v, record, field, data) {
    var c = data[field+'count'] ? ++data[field+'count'] : (data[field+'count'] = 1);
    var t = (data[field+'total'] = ((data[field+'total'] || 0) + (record.data[field] || 0)));
    return t === 0 ? 0 : t / c;
  }
}
